package main

import (
	"archive/zip"
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"
)

type auditUpstreamFixture struct {
	server        *httptest.Server
	mu            sync.Mutex
	auditQueries  []url.Values
	auditRecords  []map[string]any
	secondPage    []map[string]any
	allowedCookie string
}

func newAuditUpstreamFixture(t *testing.T) *auditUpstreamFixture {
	t.Helper()
	fixture := &auditUpstreamFixture{allowedCookie: "R_SESS=authorized"}
	fixture.server = httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.Header.Get("Cookie") != fixture.allowedCookie {
			http.Error(writer, "unauthorized", http.StatusUnauthorized)
			return
		}
		writer.Header().Set("Content-Type", "application/json")
		switch request.URL.Path {
		case "/v2-beta/projects":
			writeFixtureCollection(writer, []map[string]any{
				{"type": "project", "id": "1p1", "displayName": "正式環境"},
				{"type": "project", "id": "1p2", "name": "測試環境"},
				{"type": "environment", "id": "1e1", "name": "不可當成專案"},
			}, "")
		case "/v2-beta/accounts":
			writeFixtureCollection(writer, []map[string]any{
				{"type": "account", "id": "1a1", "name": "陳管理員", "username": "chen"},
				{"type": "account", "id": "1a2", "name": "", "username": "alice"},
			}, "")
		case "/v2-beta/auditlogs":
			fixture.mu.Lock()
			fixture.auditQueries = append(fixture.auditQueries, request.URL.Query())
			fixture.mu.Unlock()
			if request.URL.Query().Get("page") == "2" {
				writeFixtureCollection(writer, fixture.secondPage, "")
				return
			}
			next := ""
			if fixture.secondPage != nil {
				next = fixture.server.URL + "/v2-beta/auditlogs?page=2"
			}
			writeFixtureCollection(writer, fixture.auditRecords, next)
		default:
			http.NotFound(writer, request)
		}
	}))
	t.Cleanup(fixture.server.Close)
	return fixture
}

func writeFixtureCollection(writer http.ResponseWriter, records []map[string]any, next string) {
	pagination := map[string]any{}
	if next != "" {
		pagination["next"] = next
	}
	_ = json.NewEncoder(writer).Encode(map[string]any{
		"type": "collection", "resourceType": "auditLog", "data": records, "pagination": pagination,
	})
}

func newAuditTestBroker(t *testing.T, fixture *auditUpstreamFixture) *httptest.Server {
	t.Helper()
	cfg := brokerConfig{
		ListenAddress: ":0", UpstreamURL: fixture.server.URL, SessionDialURL: fixture.server.URL,
		MaxSessions: 8, ReplayBytes: 128 * 1024, ActiveTTL: time.Hour, HistoryTTL: time.Hour, CleanupInterval: time.Hour,
	}
	instance, err := newBroker(cfg, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(instance)
	t.Cleanup(func() {
		server.Close()
		instance.close()
	})
	return server
}

func auditTestRecord(id, created, project, actor, eventType, authType, description string) map[string]any {
	return map[string]any{
		"type": "auditLog", "id": id, "created": created, "accountId": project,
		"authenticatedAsAccountId": actor, "authenticatedAsIdentityId": "identity-" + actor,
		"eventType": eventType, "authType": authType, "description": description,
		"clientIp": "10.0.0.25", "resourceType": "host", "resourceId": id,
		"requestObject": map[string]any{"secret": "must-not-export"},
	}
}

func performAuditRequest(t *testing.T, server *httptest.Server, path string) *http.Response {
	t.Helper()
	request, err := http.NewRequest(http.MethodGet, server.URL+path, nil)
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Cookie", "R_SESS=authorized")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	return response
}

func TestAuditQueryEnforcesBothTimeBoundariesAndEnvironmentAuthorization(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	fixture.auditRecords = []map[string]any{
		auditTestRecord("host10", "2026-08-29T02:20:00Z", "1p1", "1a1", "resource.change10", "TokenAuth", "newer"),
		auditTestRecord("forbidden", "2026-08-29T02:15:00Z", "1p9", "1a9", "forbidden.event99", "ApiKey", "must not leak"),
		auditTestRecord("at-upper-bound", "2026-08-29T03:00:00Z", "1p1", "1a1", "resource.change11", "BasicAuth", "exclusive upper boundary"),
		auditTestRecord("too-new", "2026-08-29T03:01:00Z", "1p1", "1a1", "resource.change4", "BasicAuth", "outside upper boundary"),
		auditTestRecord("too-old", "2026-08-29T01:59:59Z", "1p1", "1a1", "resource.change1", "BasicAuth", "outside lower boundary"),
	}
	fixture.secondPage = []map[string]any{
		auditTestRecord("host2", "2026-08-29T02:10:00Z", "1p2", "1a2", "resource.change2", "ApiKey", "second page"),
	}
	server := newAuditTestBroker(t, fixture)

	response := performAuditRequest(t, server, auditQueryPath+"?created_gte=2026-08-29T02%3A00%3A00Z&created_lte=2026-08-29T03%3A00%3A00Z&sort=eventType&order=asc")
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("query returned %d: %s", response.StatusCode, body)
	}
	var payload auditCollection
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if len(payload.Data) != 2 {
		t.Fatalf("expected two authorized in-range records, got %#v", payload.Data)
	}
	if auditString(payload.Data[0], "id") != "host2" || auditString(payload.Data[1], "id") != "host10" {
		t.Fatalf("natural event sorting is incorrect: %#v", payload.Data)
	}
	if auditString(payload.Data[0], "actorDisplayName") != "alice" || auditString(payload.Data[1], "actorDisplayName") != "陳管理員" {
		t.Fatalf("friendly actor names were not applied: %#v", payload.Data)
	}
	if auditString(payload.Data[0], "interactionChannel") != "public_api" || auditString(payload.Data[1], "interactionChannel") != "web_ui" {
		t.Fatalf("interaction channels were not distinguished: %#v", payload.Data)
	}
	if len(payload.Filters) == 0 {
		t.Fatal("permission-scoped suggestions are missing")
	}
	encodedFilters, _ := json.Marshal(payload.Filters)
	if bytes.Contains(encodedFilters, []byte("1a9")) || bytes.Contains(encodedFilters, []byte("forbidden.event99")) {
		t.Fatalf("an unauthorized environment leaked into suggestions: %s", encodedFilters)
	}
	if !bytes.Contains(encodedFilters, []byte(`"label":"alice"`)) || !bytes.Contains(encodedFilters, []byte(`"label":"陳管理員"`)) {
		t.Fatalf("authorized human actor suggestions are incomplete: %s", encodedFilters)
	}
	fixture.mu.Lock()
	defer fixture.mu.Unlock()
	if len(fixture.auditQueries) != 2 {
		t.Fatalf("expected two upstream pages, got %d", len(fixture.auditQueries))
	}
	if fixture.auditQueries[0].Get("created_gte") == "" || fixture.auditQueries[0].Get("created_lte") != "" {
		t.Fatalf("upstream query must use the supported lower boundary only: %#v", fixture.auditQueries[0])
	}
}

func TestAuditQueryAppliesEverySupportedConditionAndAndSemantics(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	target := auditTestRecord("host10", "2026-08-29T02:55:00Z", "1p1", "1a1", "resource.change10", "TokenAuth", "Changed production setting")
	api := auditTestRecord("volume2", "2026-08-29T02:50:00Z", "1p1", "1a2", "resource.remove2", "ApiKey", "Removed volume")
	automation := auditTestRecord("host3", "2026-08-29T02:45:00Z", "1p1", "1a2", "host.register3", "HostRegistration", "Agent registered")
	system := auditTestRecord("environment4", "2026-08-29T02:40:00Z", "1p1", "1a1", "system.cleanup4", "None", "Scheduled cleanup")
	unknown := auditTestRecord("service5", "2026-08-29T02:35:00Z", "1p1", "1a2", "custom.observe5", "CustomAuth", "Observed custom action")
	project2 := auditTestRecord("host20", "2026-08-29T02:30:00Z", "1p2", "1a2", "resource.change20", "BasicAuth", "Changed test setting")

	api["clientIp"], api["resourceType"], api["resourceId"] = "10.0.0.26", "volume", "volume2"
	automation["clientIp"], automation["resourceType"], automation["resourceId"] = "10.0.0.27", "host", "host3"
	system["clientIp"], system["resourceType"], system["resourceId"] = "127.0.0.1", "environment", "1p1"
	unknown["clientIp"], unknown["resourceType"], unknown["resourceId"] = "10.0.0.28", "service", "service5"
	project2["clientIp"], project2["resourceType"], project2["resourceId"] = "10.0.0.29", "host", "host20"
	fixture.auditRecords = []map[string]any{target, api, automation, system, unknown, project2}
	server := newAuditTestBroker(t, fixture)

	allExceptTarget := "volume2,host3,environment4,service5,host20"
	allExceptAPI := "host10,host3,environment4,service5,host20"
	cases := []struct {
		name     string
		filter   url.Values
		expected string
	}{
		{name: "environment", filter: url.Values{"accountId": {"1p2"}}, expected: "host20"},
		{name: "user", filter: url.Values{"authenticatedAsAccountId": {"1a1"}}, expected: "host10,environment4"},
		{name: "resource type", filter: url.Values{"resourceType": {"volume"}}, expected: "volume2"},
		{name: "resource id", filter: url.Values{"resourceId": {"host3"}}, expected: "host3"},
		{name: "client IP exact", filter: url.Values{"clientIp": {"10.0.0.26"}}, expected: "volume2"},
		{name: "authentication type exact ignoring case", filter: url.Values{"authType": {"apikey"}}, expected: "volume2"},
		{name: "Web UI source", filter: url.Values{"interactionChannel": {"web_ui"}}, expected: "host10"},
		{name: "public API source", filter: url.Values{"interactionChannel": {"public_api"}}, expected: "volume2,host20"},
		{name: "automation source", filter: url.Values{"interactionChannel": {"automation"}}, expected: "host3"},
		{name: "system source", filter: url.Values{"interactionChannel": {"system_internal"}}, expected: "environment4"},
		{name: "unknown source", filter: url.Values{"interactionChannel": {"unknown"}}, expected: "service5"},
		{name: "event exact ignoring case", filter: url.Values{"eventType": {"RESOURCE.CHANGE10"}}, expected: "host10"},
		{name: "event contains ignoring case", filter: url.Values{"eventType_like": {"%CHANGE%"}}, expected: "host10,host20"},
		{name: "event starts with ignoring case", filter: url.Values{"eventType_prefix": {"RESOURCE."}}, expected: "host10,volume2,host20"},
		{name: "event is not", filter: url.Values{"eventType_ne": {"resource.change10"}}, expected: allExceptTarget},
		{name: "event does not contain", filter: url.Values{"eventType_notlike": {"%change%"}}, expected: "volume2,host3,environment4,service5"},
		{name: "description exact ignoring case", filter: url.Values{"description": {"REMOVED VOLUME"}}, expected: "volume2"},
		{name: "description contains ignoring case", filter: url.Values{"description_like": {"%SETTING%"}}, expected: "host10,host20"},
		{name: "description starts with ignoring case", filter: url.Values{"description_prefix": {"scheduled"}}, expected: "environment4"},
		{name: "description is not", filter: url.Values{"description_ne": {"removed volume"}}, expected: allExceptAPI},
		{name: "description does not contain", filter: url.Values{"description_notlike": {"%change%"}}, expected: "volume2,host3,environment4,service5"},
		{name: "all conditions use AND", filter: url.Values{
			"accountId": {"1p1"}, "authenticatedAsAccountId": {"1a1"}, "resourceType": {"host"},
			"resourceId": {"host10"}, "clientIp": {"10.0.0.25"}, "authType": {"TokenAuth"},
			"interactionChannel": {"web_ui"}, "eventType_prefix": {"resource.change"},
			"description_like": {"%production%"},
		}, expected: "host10"},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			values := url.Values{
				"created_gte": {"2026-08-29T02:00:00Z"},
				"created_lte": {"2026-08-29T03:00:00Z"},
			}
			for key, entries := range testCase.filter {
				for _, entry := range entries {
					values.Add(key, entry)
				}
			}

			response := performAuditRequest(t, server, auditQueryPath+"?"+values.Encode())
			if response.StatusCode != http.StatusOK {
				body, _ := io.ReadAll(response.Body)
				response.Body.Close()
				t.Fatalf("query returned %d: %s", response.StatusCode, body)
			}
			var payload auditCollection
			if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
				response.Body.Close()
				t.Fatal(err)
			}
			response.Body.Close()
			ids := make([]string, 0, len(payload.Data))
			for _, record := range payload.Data {
				ids = append(ids, auditString(record, "id"))
			}
			if actual := strings.Join(ids, ","); actual != testCase.expected {
				t.Fatalf("filter result=%q expected=%q", actual, testCase.expected)
			}
		})
	}
}

func TestAuditQueryRejectsAnUnauthorizedEnvironmentBeforeReadingLogs(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	server := newAuditTestBroker(t, fixture)

	response := performAuditRequest(t, server, auditQueryPath+"?accountId=1p9&created_gte=2026-08-29T02%3A00%3A00Z&created_lte=2026-08-29T03%3A00%3A00Z")
	defer response.Body.Close()
	if response.StatusCode != http.StatusForbidden {
		t.Fatalf("expected 403, got %d", response.StatusCode)
	}
	fixture.mu.Lock()
	defer fixture.mu.Unlock()
	if len(fixture.auditQueries) != 0 {
		t.Fatalf("unauthorized environment triggered an audit query: %#v", fixture.auditQueries)
	}
}

func TestAuditExportsUseTheSameFilteredRecordsAndSafeSpreadsheetText(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	authorized := auditTestRecord("event10", "2026-08-29T02:20:00Z", "1p1", "1a1", "resource.change", "BasicAuth", "=HYPERLINK(\"https://invalid\")")
	authorized["requestId"] = "request-10"
	authorized["traceID"] = "trace-2"
	fixture.auditRecords = []map[string]any{
		authorized,
		auditTestRecord("forbidden-export", "2026-08-29T02:25:00Z", "1p9", "1a1", "secret.change", "BasicAuth", "forbidden-export-value"),
	}
	server := newAuditTestBroker(t, fixture)
	base := auditExportPath + "?created_gte=2026-08-29T02%3A00%3A00Z&created_lte=2026-08-29T03%3A00%3A00Z"

	csvResponse := performAuditRequest(t, server, base+"&format=csv")
	csvBody, _ := io.ReadAll(csvResponse.Body)
	csvResponse.Body.Close()
	if csvResponse.StatusCode != http.StatusOK || !bytes.HasPrefix(csvBody, []byte{0xEF, 0xBB, 0xBF}) {
		t.Fatalf("CSV response is invalid: status=%d body=%q", csvResponse.StatusCode, csvBody)
	}
	if !bytes.Contains(csvBody, []byte("'=HYPERLINK")) || !bytes.Contains(csvBody, []byte("event10")) || !bytes.Contains(csvBody, []byte("request-10")) || !bytes.Contains(csvBody, []byte("trace-2")) || bytes.Contains(csvBody, []byte("must-not-export")) || bytes.Contains(csvBody, []byte("forbidden-export")) {
		t.Fatalf("CSV did not neutralize formulas or leaked hidden payloads: %q", csvBody)
	}
	if csvResponse.Header.Get("Content-Security-Policy") != "sandbox" || csvResponse.Header.Get("Referrer-Policy") != "no-referrer" || csvResponse.Header.Get("Cache-Control") != "no-store" {
		t.Fatalf("export security headers are incomplete: %#v", csvResponse.Header)
	}

	jsonResponse := performAuditRequest(t, server, base+"&format=json")
	jsonBody, _ := io.ReadAll(jsonResponse.Body)
	jsonResponse.Body.Close()
	if !bytes.Contains(jsonBody, []byte(`"count": 1`)) || !bytes.Contains(jsonBody, []byte(`"rangeSemantics": "[from,to)"`)) || !bytes.Contains(jsonBody, []byte(`"requestId": "request-10"`)) || bytes.Contains(jsonBody, []byte("must-not-export")) || bytes.Contains(jsonBody, []byte("forbidden-export")) {
		t.Fatalf("JSON export is invalid: %s", jsonBody)
	}

	xlsxResponse := performAuditRequest(t, server, base+"&format=xlsx")
	xlsxBody, _ := io.ReadAll(xlsxResponse.Body)
	xlsxResponse.Body.Close()
	archive, err := zip.NewReader(bytes.NewReader(xlsxBody), int64(len(xlsxBody)))
	if err != nil {
		t.Fatalf("XLSX is not a valid ZIP: %v", err)
	}
	foundSheet := false
	for _, file := range archive.File {
		if file.Name != "xl/worksheets/sheet1.xml" {
			continue
		}
		foundSheet = true
		reader, err := file.Open()
		if err != nil {
			t.Fatal(err)
		}
		sheet, _ := io.ReadAll(reader)
		reader.Close()
		if !bytes.Contains(sheet, []byte(`<autoFilter ref="A1:M2"/>`)) || !bytes.Contains(sheet, []byte("Event ID")) || !bytes.Contains(sheet, []byte("Request ID")) || !bytes.Contains(sheet, []byte("&#39;=HYPERLINK")) || bytes.Contains(sheet, []byte("must-not-export")) || bytes.Contains(sheet, []byte("forbidden-export")) {
			t.Fatalf("XLSX sheet is missing safety or usability features: %s", sheet)
		}
	}
	if !foundSheet {
		t.Fatal("XLSX worksheet is missing")
	}
}

func TestParseAuditQueryRejectsAmbiguousOrExcessiveTimeRanges(t *testing.T) {
	now := time.Date(2026, 8, 29, 3, 0, 0, 0, time.UTC)
	if _, err := parseAuditQuery(url.Values{"created_gte": {"2026-08-29T02:00:00Z"}}, now); err == nil {
		t.Fatal("one-sided time range was accepted")
	}
	if _, err := parseAuditQuery(url.Values{
		"created_gte": {"2025-01-01T00:00:00Z"}, "created_lte": {"2026-08-29T00:00:00Z"},
	}, now); err == nil {
		t.Fatal("excessive time range was accepted")
	}
	if _, err := parseAuditQuery(url.Values{
		"created_gte": {"2026-08-29T02:00:00Z"}, "created_lte": {"2026-08-29T02:00:00Z"},
	}, now); err == nil {
		t.Fatal("zero-width half-open time range was accepted")
	}
	channelQuery, err := parseAuditQuery(url.Values{"interactionChannel": {"PUBLIC_API"}}, now)
	if err != nil || channelQuery.Channel != "public_api" {
		t.Fatalf("interaction channel normalization failed: %#v %v", channelQuery, err)
	}
	query, err := parseAuditQuery(url.Values{}, now)
	if err != nil {
		t.Fatal(err)
	}
	if query.To.Sub(query.From) != auditDefaultRange {
		t.Fatalf("default range is not bounded: %#v", query)
	}
}

func TestAuditInteractionChannelClassification(t *testing.T) {
	cases := map[string]string{
		"TokenAuth": "web_ui", "BasicAuth": "public_api", "ApiKey": "public_api",
		"HeaderAuth": "public_api", "TokenAccount": "public_api", "RegistrationToken": "automation",
		"HostRegistration": "automation", "AdminAuth": "system_internal", "None": "system_internal", "custom": "unknown",
	}
	for authType, expected := range cases {
		if actual := auditInteractionChannel(map[string]any{"authType": authType}); actual != expected {
			t.Fatalf("%s classified as %s, expected %s", authType, actual, expected)
		}
	}
	if actual := auditInteractionChannel(map[string]any{"authType": "TokenAuth", "interactionChannel": "public_api"}); actual != "public_api" {
		t.Fatalf("an explicitly recorded valid channel was overwritten: %s", actual)
	}
}

func TestAuditNaturalSortUsesDisplayNamesAndNumericSegments(t *testing.T) {
	records := []map[string]any{
		{"id": "event10", "environmentDisplayName": "環境10", "actorDisplayName": "User 10"},
		{"id": "event2", "environmentDisplayName": "環境2", "actorDisplayName": "User 2"},
	}
	if compareAuditRecords(records[0], records[1], "id") <= 0 {
		t.Fatal("event IDs were not naturally sorted")
	}
	if compareAuditRecords(records[0], records[1], "accountId") <= 0 {
		t.Fatal("environment sorting did not use human display names")
	}
	if compareAuditRecords(records[0], records[1], "authenticatedAsIdentityId") <= 0 {
		t.Fatal("identity sorting did not use human actor names")
	}
}

func TestAuditEndpointRejectsNonGetMethods(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	server := newAuditTestBroker(t, fixture)
	request, _ := http.NewRequest(http.MethodPost, server.URL+auditQueryPath, strings.NewReader("{}"))
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusMethodNotAllowed || response.Header.Get("Allow") != "GET" {
		t.Fatalf("unexpected method response: %d %q", response.StatusCode, response.Header.Get("Allow"))
	}
}
