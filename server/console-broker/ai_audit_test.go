package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

const aiAuditRange = `"from":"2026-10-01T00:00:00Z","to":"2026-10-02T00:00:00Z"`

// These tests call the isolated query owner. Public fixed forwarding has a separate gateway test.
func postAIAudit(t *testing.T, server *httptest.Server, payload, cookie, authorization string) (int, map[string]any, string) {
	t.Helper()
	request, err := http.NewRequest(http.MethodPost, server.URL+aiAuditQueryPath, strings.NewReader(payload))
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Content-Type", "application/json")
	if cookie != "" {
		request.Header.Set("Cookie", cookie)
	}
	if authorization != "" {
		request.Header.Set("Authorization", authorization)
	}
	response, err := server.Client().Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(response.Body, 65536))
	if err != nil {
		t.Fatal(err)
	}
	var body map[string]any
	if err := json.Unmarshal(raw, &body); err != nil {
		t.Fatal("typed response was not JSON")
	}
	return response.StatusCode, body, string(raw)
}

func TestAIAuditNativeOwnerQueryPaginationAndSafeDetail(t *testing.T) {
	upstream := newAuditUpstreamFixture(t)
	for _, id := range []string{"audit1", "audit2"} {
		row := auditTestRecord(id, "2026-10-01T12:00:00Z", "1p1", "1a1", "api.service.update", "TokenAuth", "PRIVATE_DESCRIPTION")
		row["decision"], row["outcome"], row["httpStatus"] = "DENY", "FAILED", 403
		row["responseObject"] = map[string]any{"jwt": "PRIVATE_RESPONSE"}
		upstream.auditRecords = append(upstream.auditRecords, row)
	}
	upstream.auditRecords = append(upstream.auditRecords,
		auditTestRecord("foreign", "2026-10-01T12:00:00Z", "foreign-project", "1a1", "event", "TokenAuth", "PRIVATE_FOREIGN"))
	server := newAuditTestBroker(t, upstream, true)
	payload := `{` + aiAuditRange + `,"environmentId":"1p1","decision":"DENY","limit":1}`
	status, body, raw := postAIAudit(t, server, payload, "R_SESS=authorized", "")
	if status != 200 || body["total"] != float64(2) || body["nextOffset"] != float64(1) {
		t.Fatal("native authorized query/page did not match")
	}
	if strings.Contains(raw, "PRIVATE_") || strings.Contains(raw, "must-not-export") || strings.Contains(raw, "requestObject") {
		t.Fatal("private native payload reached typed metadata")
	}
	first := body["data"].([]any)[0].(map[string]any)
	if first["payloadsIncluded"] != false || first["responsePayloadPresence"] != "present" || first["httpStatus"] != float64(403) {
		t.Fatal("safe payload policy or HTTP metadata missing")
	}
	status, second, _ := postAIAudit(t, server, `{`+aiAuditRange+`,"environmentId":"1p1","decision":"DENY","limit":1,"offset":1}`, "R_SESS=authorized", "")
	if status != 200 || second["nextOffset"] != nil || second["data"].([]any)[0].(map[string]any)["id"] == first["id"] {
		t.Fatal("native second page was not distinct and terminal")
	}
	status, detail, _ := postAIAudit(t, server, `{`+aiAuditRange+`,"environmentId":"1p1","eventId":"`+first["id"].(string)+`"}`, "R_SESS=authorized", "")
	if status != 200 || len(detail["data"].([]any)) != 1 {
		t.Fatal("exact authorized event detail failed")
	}
	status, _, _ = postAIAudit(t, server, `{`+aiAuditRange+`,"environmentId":"1p1","eventId":"foreign"}`, "R_SESS=authorized", "")
	if status != 404 {
		t.Fatal("foreign event escaped original owner query scope")
	}
}

func TestAIAuditKeyFilterReusesLiveAuthorityAndCannotReadAnotherKey(t *testing.T) {
	fixture, server := newKeyAuditFixture(t, true)
	fixture.keyID = "1c99"
	fixture.records = []map[string]any{
		keyAuditRecord("own-event", "1c99", "1p1", "2026-10-01T12:00:00Z"),
		keyAuditRecord("other-event", "1c100", "1p1", "2026-10-01T12:00:00Z"),
	}
	payload := `{` + aiAuditRange + `,"keyId":"1c99","environmentId":"1p1","decision":"ALLOW"}`
	status, body, raw := postAIAudit(t, server, payload, "R_SESS=authorized", "")
	if status != 200 || len(body["data"].([]any)) != 1 || len(fixture.keyQueries) == 0 || strings.Contains(raw, "secret") {
		t.Fatal("exact Key audit owner/projection failed")
	}
	status, _, _ = postAIAudit(t, server, `{`+aiAuditRange+`,"keyId":"1c99","eventId":"other-event"}`, "R_SESS=authorized", "")
	if status != 404 {
		t.Fatal("cross-Key detail was not refused")
	}
	fixture.keyStatus = http.StatusForbidden
	status, _, _ = postAIAudit(t, server, payload, "R_SESS=authorized", "")
	if status != 403 {
		t.Fatal("Key visibility loss was not rechecked")
	}
}

func TestAIAuditStrictInputsAndNativeCookieBoundary(t *testing.T) {
	upstream := newAuditUpstreamFixture(t)
	server := newAuditTestBroker(t, upstream, true)
	for _, payload := range []string{
		`null`, `{"url":"https://outside.invalid"}`, `{"actorId":"1a1"}`,
		`{"limit":51}`, `{"offset":20000}`, `{"lastMinutes":0}`,
		`{"lastMinutes":1,"from":"2026-10-01T00:00:00Z"}`,
		`{"from":"2026-10-01T00:00:00"}`, `{"decision":"ALLOW OR DENY"}`,
		`{} {}`, `{"requestId":"` + strings.Repeat("x", 9000) + `"}`,
	} {
		status, _, _ := postAIAudit(t, server, payload, "R_SESS=authorized", "")
		if status != 400 && status != 422 {
			t.Fatal("invalid typed input was accepted")
		}
	}
	for _, credentials := range [][2]string{{"", ""}, {"", "Basic not-a-cookie"}, {"R_SESS=authorized", "Basic not-a-cookie"}} {
		status, body, _ := postAIAudit(t, server, "{}", credentials[0], credentials[1])
		if status != 403 || body["code"] != "ai_audit_cookie_required" {
			t.Fatal("unsupported transport did not fail closed")
		}
	}
	if len(upstream.auditQueries) != 0 {
		t.Fatal("rejected inputs/transport reached audit data")
	}
}

func TestAIAuditSessionAndEnvironmentLossNeverReturnPartialRows(t *testing.T) {
	upstream := newAuditUpstreamFixture(t)
	server := newAuditTestBroker(t, upstream, true)
	for _, test := range []struct {
		cookie, payload string
		status          int
	}{
		{"R_SESS=expired", "{}", 401},
		{"R_SESS=authorized", `{"environmentId":"unavailable"}`, 403},
	} {
		status, body, _ := postAIAudit(t, server, test.payload, test.cookie, "")
		if status != test.status || body["data"] != nil {
			t.Fatal("current authorization rejection returned success/partial data")
		}
	}
	if len(upstream.auditQueries) != 0 {
		t.Fatal("failed authority read reached audit data")
	}
}

func TestAIAuditRejectsRedirectBeforeAnyForeignSourceCall(t *testing.T) {
	hits := 0
	foreign := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits++
		w.WriteHeader(http.StatusOK)
	}))
	defer foreign.Close()
	upstream := &auditUpstreamFixture{server: httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, foreign.URL, http.StatusFound)
	}))}
	defer upstream.server.Close()
	server := newAuditTestBroker(t, upstream, true)
	status, _, _ := postAIAudit(t, server, "{}", "R_SESS=authorized", "")
	if status != 502 || hits != 0 {
		t.Fatal("typed native audit followed an authority redirect")
	}
}

func TestAIAuditLegacyHumanAuditPayloadContractIsUnchanged(t *testing.T) {
	upstream := newAuditUpstreamFixture(t)
	upstream.auditRecords = []map[string]any{
		auditTestRecord("legacy", "2026-10-01T12:00:00Z", "1p1", "1a1", "event", "TokenAuth", "human description"),
	}
	server := newAuditTestBroker(t, upstream, true)
	response := performAuditRequest(t, server, auditQueryPath+"?createdFrom=2026-10-01T00:00:00Z&createdTo=2026-10-02T00:00:00Z")
	defer response.Body.Close()
	body, _ := io.ReadAll(response.Body)
	if response.StatusCode != 200 || !strings.Contains(string(body), "requestObject") {
		t.Fatal("ordinary human audit detail was changed by the typed adapter")
	}
}

func TestAIAuditOriginalOwnerScanLimitReturnsNoPartialProjection(t *testing.T) {
	upstream := newAuditUpstreamFixture(t)
	record := map[string]any{"id": "bounded", "accountId": "1p1", "created": "2026-10-01T12:00:00Z"}
	upstream.auditRecords = make([]map[string]any, auditMaximumScanRows+1)
	for index := range upstream.auditRecords {
		upstream.auditRecords[index] = record
	}
	server := newAuditTestBroker(t, upstream, true)
	status, body, _ := postAIAudit(t, server, `{`+aiAuditRange+`}`, "R_SESS=authorized", "")
	if status != 422 || body["code"] != "result_set_too_large" || body["data"] != nil {
		t.Fatal("original owner's scan bound was bypassed or returned partial success")
	}
}

func TestAIAuditCallerHeadersCannotSupplyOwnerIdentityOrProject(t *testing.T) {
	calls := 0
	upstream := &auditUpstreamFixture{server: httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		if r.Header.Get("Cookie") != "R_SESS=authorized" || r.Header.Get("X-Forwarded-User") != "" ||
			r.Header.Get("X-Api-Auth-Header") != "" || r.Header.Get("X-API-Project-ID") != "" {
			t.Error("new route forwarded caller-selected authority")
			w.WriteHeader(500)
			return
		}
		w.Header().Set("X-API-USER-ID", "1a1")
		switch r.URL.Path {
		case "/v2-beta/projects":
			writeFixtureCollection(w, []map[string]any{{"id": "1p1", "type": "project"}}, "")
		case "/v2-beta/accounts":
			writeFixtureCollection(w, nil, "")
		case "/v2-beta/auditlogs":
			writeFixtureCollection(w, []map[string]any{
				auditTestRecord("event", "2026-10-01T12:00:00Z", "1p1", "1a1", "event", "TokenAuth", "private"),
			}, "")
		default:
			t.Error("unexpected native owner route")
			w.WriteHeader(500)
		}
	}))}
	defer upstream.server.Close()
	server := newAuditTestBroker(t, upstream, true)
	request, _ := http.NewRequest("POST", server.URL+aiAuditQueryPath, strings.NewReader(`{`+aiAuditRange+`,"environmentId":"1p1"}`))
	request.Header.Set("Cookie", "R_SESS=authorized")
	request.Header.Set("X-Forwarded-User", "forged-actor")
	request.Header.Set("X-Api-Auth-Header", "forged-identity")
	request.Header.Set("X-API-Project-ID", "foreign-project")
	response, err := server.Client().Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != 200 || calls != 3 {
		t.Fatal("native owner identity was not kept independent of caller headers")
	}
}
