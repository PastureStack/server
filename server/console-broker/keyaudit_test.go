package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"testing"
)

type keyAuditFixture struct {
	mu                   sync.Mutex
	owner                string
	keyStatus            int
	restricted           bool
	viewer               string
	projects             []map[string]any
	records              []map[string]any
	auditQueries         []url.Values
	accountScoped        bool
	deniedProject        string
	projectPagination    bool
	projectAuthorityNext bool
}

func newKeyAuditFixture(t *testing.T) (*keyAuditFixture, *httptest.Server) {
	t.Helper()
	fixture := &keyAuditFixture{
		owner: "1a1", viewer: "1a1", keyStatus: http.StatusOK,
		projects: []map[string]any{{"type": "project", "id": "1p1", "name": "Production"}},
	}
	upstream := &auditUpstreamFixture{}
	upstream.server = httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.Header.Get("Cookie") != "R_SESS=authorized" {
			http.Error(writer, "unauthorized", http.StatusUnauthorized)
			return
		}
		fixture.mu.Lock()
		defer fixture.mu.Unlock()
		switch request.URL.Path {
		case "/v2-beta/apikey/1a99", "/v2-beta/apikeyrestricted/1a99":
			kind := "apiKey"
			if strings.Contains(request.URL.Path, "apikeyrestricted") {
				if !fixture.restricted {
					http.NotFound(writer, request)
					return
				}
				kind = "apiKeyRestricted"
			} else if fixture.restricted {
				http.NotFound(writer, request)
				return
			}
			writer.Header().Set("X-API-USER-ID", fixture.viewer)
			writer.WriteHeader(fixture.keyStatus)
			_ = json.NewEncoder(writer).Encode(map[string]any{"type": kind, "id": "1a99", "accountId": fixture.owner, "secretValue": "never-return-key-secret"})
		case "/v2-beta/projects":
			next := ""
			if fixture.projectAuthorityNext {
				next = upstream.server.URL + "/v2-beta/projects?marker=more"
			}
			writeFixtureCollection(writer, fixture.projects, next)
		case "/v2-beta/accounts":
			writeFixtureCollection(writer, []map[string]any{{"type": "account", "id": "1a1", "name": "Owner"}}, "")
		case "/v2-beta/auditlogs":
			fixture.auditQueries = append(fixture.auditQueries, request.URL.Query())
			if !fixture.accountScoped {
				writeFixtureCollection(writer, fixture.records, "")
				break
			}
			projectID := request.URL.Query().Get("projectId")
			if projectID != "" && projectID == fixture.deniedProject {
				http.Error(writer, "forbidden", http.StatusForbidden)
				break
			}
			accountID := fixture.viewer
			if projectID != "" {
				accountID = projectID
			}
			var records []map[string]any
			for _, record := range fixture.records {
				if auditString(record, "accountId") == accountID {
					records = append(records, record)
				}
			}
			next := ""
			if projectID != "" && fixture.projectPagination && request.URL.Query().Get("marker") == "" && len(records) > 1 {
				records = records[:1]
				// Real Engine next URLs can omit request-local project context.
				next = upstream.server.URL + "/v2-beta/auditlogs?marker=second"
			} else if request.URL.Query().Get("marker") == "second" && len(records) > 1 {
				records = records[1:]
			}
			writeFixtureCollection(writer, records, next)
		default:
			http.NotFound(writer, request)
		}
	}))
	t.Cleanup(upstream.server.Close)
	return fixture, newAuditTestBroker(t, upstream)
}

func keyAuditRecord(id, keyID, project, created string) map[string]any {
	record := auditTestRecord(id, created, project, "1a1", "api.stack.read", "BasicAuth", "payload-must-not-leak")
	for key, value := range map[string]any{
		"keyId": keyID, "decision": "ALLOW", "outcome": "SUCCEEDED", "httpStatus": 200,
		"operation": "read", "requestId": "request-123", "targetType": "stack", "targetId": "1st1",
		"policyRevision": 3, "phase": "response", "preview": false,
	} {
		record[key] = value
	}
	record["Authorization"] = "Bearer-secret"
	record["responseObject"] = map[string]any{"Cookie": "session-secret", "jwt": "jwt-secret", "oidcCode": "code-secret"}
	return record
}

func TestKeyAuditFiltersBeforeCountAndPaginationAndAllTimeIncludesOldReads(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.records = []map[string]any{
		keyAuditRecord("event1", "1a99", "1p1", "2020-01-01T00:00:00Z"),
		keyAuditRecord("event2", "1a99", "1p1", "2021-01-01T00:00:00Z"),
		keyAuditRecord("foreign-key", "1a98", "1p1", "2022-01-01T00:00:00Z"),
		keyAuditRecord("hidden-project", "1a99", "1p9", "2023-01-01T00:00:00Z"),
	}
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all&limit=1&offset=1&order=asc")
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("key query status %d", response.StatusCode)
	}
	bytes, _ := io.ReadAll(response.Body)
	var payload auditCollection
	if err := json.Unmarshal(bytes, &payload); err != nil {
		t.Fatal(err)
	}
	if len(payload.Data) != 1 || auditString(payload.Data[0], "id") != "event2" || payload.Pagination["total"] != float64(2) {
		t.Fatalf("count/pagination included unauthorized rows: %s", bytes)
	}
	for _, secret := range []string{"Bearer-secret", "session-secret", "jwt-secret", "code-secret", "payload-must-not-leak", "never-return-key-secret", "foreign-key", "hidden-project"} {
		if strings.Contains(string(bytes), secret) {
			t.Fatalf("unsafe query response retained %s", secret)
		}
	}
	if len(fixture.auditQueries) != 2 || fixture.auditQueries[0].Get("created_gte") != "" || fixture.auditQueries[1].Get("created_gte") != "" {
		t.Fatalf("all-time query kept a lower time boundary: %#v", fixture.auditQueries)
	}
}

func TestKeyAuditReadonlyOwnKeyUsesLiveProjectContextBeforeCountAndDetail(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.accountScoped = true
	fixture.records = []map[string]any{
		keyAuditRecord("personal", "1a99", "1a1", "2020-01-01T00:00:00Z"),
		keyAuditRecord("decision", "1a99", "1p1", "2021-01-01T00:00:00Z"),
		keyAuditRecord("response405", "1a99", "1p1", "2022-01-01T00:00:00Z"),
		keyAuditRecord("hidden", "1a99", "1p9", "2023-01-01T00:00:00Z"),
		keyAuditRecord("foreign", "1a98", "1p1", "2024-01-01T00:00:00Z"),
	}
	fixture.records[2]["outcome"], fixture.records[2]["httpStatus"] = "FAILED", 405
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all&limit=1&offset=1&order=asc")
	defer response.Body.Close()
	var payload auditCollection
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK || payload.Pagination["total"] != float64(3) || len(payload.Data) != 1 || auditString(payload.Data[0], "id") != "decision" {
		t.Fatalf("live project rows missing before count/pagination: %d %#v", response.StatusCode, payload)
	}
	detail := performAuditRequest(t, server, keyAuditQueryPath+"/response405?keyId=1a99")
	defer detail.Body.Close()
	if detail.StatusCode != http.StatusOK {
		t.Fatalf("own denied update event missing: %d", detail.StatusCode)
	}
	for _, id := range []string{"foreign", "hidden"} {
		hidden := performAuditRequest(t, server, keyAuditQueryPath+"/"+id+"?keyId=1a99")
		hidden.Body.Close()
		if hidden.StatusCode != http.StatusNotFound {
			t.Fatalf("foreign/currently inaccessible event escaped: %s %d", id, hidden.StatusCode)
		}
	}
}

func TestKeyAuditProjectContextSurvivesPaginationAndRoleLossFailsClosed(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.accountScoped, fixture.projectPagination = true, true
	fixture.records = []map[string]any{
		keyAuditRecord("decision", "1a99", "1p1", "2021-01-01T00:00:00Z"),
		keyAuditRecord("response", "1a99", "1p1", "2022-01-01T00:00:00Z"),
	}
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all")
	defer response.Body.Close()
	var payload auditCollection
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK || payload.Pagination["total"] != float64(2) {
		t.Fatalf("later page lost verified project context: %d %#v", response.StatusCode, payload)
	}
	fixture.mu.Lock()
	fixture.deniedProject = "1p1"
	fixture.mu.Unlock()
	lost := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all")
	defer lost.Body.Close()
	if lost.StatusCode != http.StatusForbidden {
		t.Fatalf("mid-query live role loss returned partial collection: %d", lost.StatusCode)
	}
}

func TestKeyAuditDoesNotTrustCallerProjectHeaderOrReturnForeignPersonalKey(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.accountScoped = true
	fixture.records = []map[string]any{keyAuditRecord("hidden", "1a99", "1p9", "2020-01-01T00:00:00Z")}
	request, _ := http.NewRequest(http.MethodGet, server.URL+keyAuditQueryPath+"?keyId=1a99&timeScope=all", nil)
	request.Header.Set("Cookie", "R_SESS=authorized")
	request.Header.Set("X-API-Project-ID", "1p9")
	response, err := server.Client().Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	var payload auditCollection
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK || payload.Pagination["total"] != float64(0) {
		t.Fatalf("caller project header was treated as a grant: %d %#v", response.StatusCode, payload)
	}
	fixture.mu.Lock()
	fixture.owner = "1a2"
	fixture.mu.Unlock()
	foreign := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all")
	defer foreign.Body.Close()
	if foreign.StatusCode != http.StatusForbidden {
		t.Fatalf("foreign personal key ceiling relaxed: %d", foreign.StatusCode)
	}
}

func TestKeyAuditCombinedProjectScanBoundCannotBeBypassed(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.accountScoped = true
	fixture.projects = []map[string]any{{"type": "project", "id": "1p1"}, {"type": "project", "id": "1p2"}}
	for index := 0; index <= auditMaximumScanRows; index++ {
		account := "1p1"
		if index%2 != 0 {
			account = "1p2"
		}
		fixture.records = append(fixture.records, map[string]any{
			"id": "event" + strconv.Itoa(index), "accountId": account,
			"keyId": "1a99", "created": "2020-01-01T00:00:00Z",
		})
	}
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all")
	defer response.Body.Close()
	body, _ := io.ReadAll(response.Body)
	if response.StatusCode != http.StatusUnprocessableEntity || !strings.Contains(string(body), "result_set_too_large") {
		t.Fatalf("combined contexts exceeded global scan bound: %d", response.StatusCode)
	}
}

func TestKeyAuditIncompleteLiveProjectAuthorityNeverReturnsPartialCounts(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.projectAuthorityNext = true
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timeScope=all")
	defer response.Body.Close()
	body, _ := io.ReadAll(response.Body)
	if response.StatusCode != http.StatusUnprocessableEntity || !strings.Contains(string(body), "result_set_too_large") {
		t.Fatalf("partial project authority claimed complete Key audit results: %d", response.StatusCode)
	}
	if len(fixture.auditQueries) != 0 {
		t.Fatal("partial authority was used for an audit scan")
	}
}

func TestKeyAuditDetailCannotEscapeKeyOrCurrentProjectPermissions(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.records = []map[string]any{
		keyAuditRecord("allowed", "1a99", "1p1", "2020-01-01T00:00:00Z"),
		keyAuditRecord("foreign", "1a98", "1p1", "2020-01-01T00:00:00Z"),
		keyAuditRecord("hidden", "1a99", "1p9", "2020-01-01T00:00:00Z"),
	}
	for _, id := range []string{"foreign", "hidden"} {
		response := performAuditRequest(t, server, keyAuditQueryPath+"/"+id+"?keyId=1a99")
		response.Body.Close()
		if response.StatusCode != http.StatusNotFound {
			t.Fatalf("detail %s bypassed current scope: %d", id, response.StatusCode)
		}
	}
	response := performAuditRequest(t, server, keyAuditQueryPath+"/allowed?keyId=1a99")
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("historical authorized detail unavailable: %d", response.StatusCode)
	}
	fixture.mu.Lock()
	fixture.projects = nil
	fixture.mu.Unlock()
	lost := performAuditRequest(t, server, keyAuditQueryPath+"/allowed?keyId=1a99")
	defer lost.Body.Close()
	if lost.StatusCode != http.StatusNotFound {
		t.Fatalf("detail reused stale RBAC after project removal: %d", lost.StatusCode)
	}
}

func TestKeyAuditDeniesForeignPersonalKeyAndReportsLostEnvironmentAccess(t *testing.T) {
	for _, owner := range []string{"1a2", "1p9"} {
		t.Run(owner, func(t *testing.T) {
			fixture, server := newKeyAuditFixture(t)
			fixture.owner = owner
			response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
			defer response.Body.Close()
			body, _ := io.ReadAll(response.Body)
			if response.StatusCode != http.StatusForbidden || !strings.Contains(string(body), "key_audit_access_lost") {
				t.Fatalf("foreign key owner was allowed: %d %s", response.StatusCode, body)
			}
			if len(fixture.auditQueries) != 0 {
				t.Fatal("unauthorized key lookup triggered an audit scan")
			}
		})
	}
}

func TestKeyAuditLostCredentialAccessDoesNotUseCachedAuthorization(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
	response.Body.Close()
	fixture.mu.Lock()
	fixture.keyStatus = http.StatusNotFound
	fixture.mu.Unlock()
	lost := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
	defer lost.Body.Close()
	body, _ := io.ReadAll(lost.Body)
	if lost.StatusCode != http.StatusForbidden || !strings.Contains(string(body), "key_audit_access_lost") {
		t.Fatalf("removed key reused stale authorization: %d %s", lost.StatusCode, body)
	}
}

func TestKeyAuditRequiresKeyIDAndSupportsResultFilters(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.records = []map[string]any{keyAuditRecord("success", "1a99", "1p1", "2020-01-01T00:00:00Z")}
	missing := performAuditRequest(t, server, keyAuditQueryPath+"?timescope=all")
	missing.Body.Close()
	if missing.StatusCode != http.StatusBadRequest {
		t.Fatalf("missing key scope accepted: %d", missing.StatusCode)
	}
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all&outcome=FAILED")
	defer response.Body.Close()
	var payload auditCollection
	if json.NewDecoder(response.Body).Decode(&payload) != nil || len(payload.Data) != 0 || payload.Pagination["total"] != float64(0) {
		t.Fatal("actual outcome filter was not applied before count")
	}
}

func TestKeyAuditKeepsV518TimeScopeContractAndSupportsOnlyKeyRouteAlias(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.records = []map[string]any{keyAuditRecord("historical", "1a99", "1p1", "2020-01-01T00:00:00Z")}
	for _, parameter := range []string{"timeScope=all", "timescope=all"} {
		response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&"+parameter)
		var payload auditCollection
		err := json.NewDecoder(response.Body).Decode(&payload)
		response.Body.Close()
		if response.StatusCode != http.StatusOK || err != nil || len(payload.Data) != 1 {
			t.Fatalf("historical Key audit query lost timeScope compatibility: %s status=%d err=%v", parameter, response.StatusCode, err)
		}
	}
}

func TestKeyAuditRestrictedCredentialUsesSameStableKeyIdentifier(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.restricted = true
	fixture.records = []map[string]any{keyAuditRecord("event1", "1a99", "1p1", "2020-01-01T00:00:00Z")}
	response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
	defer response.Body.Close()
	var payload auditCollection
	if response.StatusCode != http.StatusOK || json.NewDecoder(response.Body).Decode(&payload) != nil || len(payload.Data) != 1 {
		t.Fatal("restricted credential authority fallback lost the stable key ID")
	}
}

func TestKeyAuditTrustsEngineViewerIdentityAndFailsClosedWhenMissing(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.owner = "1a2"
	request, _ := http.NewRequest(http.MethodGet, server.URL+keyAuditQueryPath+"?keyId=1a99&timescope=all", nil)
	request.Header.Set("Cookie", "R_SESS=authorized")
	request.Header.Set("X-API-USER-ID", "1a2")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	response.Body.Close()
	if response.StatusCode != http.StatusForbidden {
		t.Fatalf("browser-controlled actor header bypassed Engine principal: %d", response.StatusCode)
	}
	fixture.mu.Lock()
	fixture.owner, fixture.viewer = "1a1", ""
	fixture.mu.Unlock()
	missing := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
	defer missing.Body.Close()
	body, _ := io.ReadAll(missing.Body)
	if missing.StatusCode != http.StatusBadGateway || !strings.Contains(string(body), "invalid_key_authority") {
		t.Fatalf("missing trusted actor failed open: %d %s", missing.StatusCode, body)
	}
}

func TestKeyAuditUpstreamAuthenticationFailuresReturnStableCodes(t *testing.T) {
	for status, code := range map[int]string{
		http.StatusUnauthorized:       "key_audit_session_expired",
		http.StatusForbidden:          "key_audit_access_lost",
		http.StatusServiceUnavailable: "key_audit_unavailable",
	} {
		t.Run(code, func(t *testing.T) {
			fixture, server := newKeyAuditFixture(t)
			fixture.keyStatus = status
			response := performAuditRequest(t, server, keyAuditQueryPath+"?keyId=1a99&timescope=all")
			defer response.Body.Close()
			body, _ := io.ReadAll(response.Body)
			if !strings.Contains(string(body), code) || len(fixture.auditQueries) != 0 {
				t.Fatalf("unverified authority started an audit query or returned an unclear error: %d %s", response.StatusCode, body)
			}
		})
	}
}
