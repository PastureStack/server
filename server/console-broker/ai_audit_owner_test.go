package main

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func ownerTestBroker(t *testing.T, handler http.Handler) *broker {
	t.Helper()
	upstream := httptest.NewServer(handler)
	t.Cleanup(upstream.Close)
	b, err := newBroker(brokerConfig{UpstreamURL: upstream.URL, SessionDialURL: upstream.URL, MaxSessions: 1, ReplayBytes: 65536,
		ActiveTTL: time.Hour, HistoryTTL: time.Hour, CleanupInterval: time.Hour}, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(b.close)
	return b
}

func ownerInput() aiAuditOwnerInput {
	return aiAuditOwnerInput{Query: &aiAuditInput{From: "2026-10-01T00:00:00Z", To: "2026-10-02T00:00:00Z", EnvironmentID: "1a5"},
		ActorID: "1a1", Authorization: "Basic PRIVATE_VERIFIED_CREDENTIAL", CredentialID: "1c8", CredentialKind: "apiKey", Revision: 3}
}

func ownerFrame(t *testing.T, b *broker, input aiAuditOwnerInput) (int, map[string]any, string) {
	t.Helper()
	var output bytes.Buffer
	if executeAIAuditOwner(b, input, &output) != 0 {
		t.Fatal("owner produced no complete frame")
	}
	var result struct {
		Status int
		Body   map[string]any
	}
	if json.Unmarshal(output.Bytes(), &result) != nil {
		t.Fatal("owner frame invalid")
	}
	return result.Status, result.Body, output.String()
}

func sourceFixture(t *testing.T, mutate func(string, map[string]any, map[string]any) int) http.Handler {
	t.Helper()
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" || r.URL.Path != "/v2-beta/aiResourceViews" || r.URL.RawQuery != "" ||
			r.Header.Get("Authorization") != "Basic PRIVATE_VERIFIED_CREDENTIAL" ||
			r.Header.Get("X-PastureStack-Key-Expected-Revision") != "3" ||
			r.Header.Get("Cookie") != "" || r.Header.Get("X-Forwarded-User") != "" {
			t.Error("source escaped exact private caller binding")
			w.WriteHeader(500)
			return
		}
		var input map[string]any
		if json.NewDecoder(r.Body).Decode(&input) != nil {
			t.Fatal("source input invalid")
		}
		category := auditString(input, "resourceType")
		page := input["sourcePage"].(map[string]any)
		project := auditString(page, "projectId")
		authority := map[string]any{"actorId": "1a1", "accountId": firstNonEmpty(project, "1a1"), "credentialId": "1c8", "credentialKind": "apiKey", "credentialRevision": 3}
		rows := []map[string]any{}
		switch category {
		case "project":
			rows = append(rows, map[string]any{"id": "1a5", "type": "project", "name": "Visible"})
		case "account":
			rows = append(rows, map[string]any{"id": "1a1", "type": "account", "name": "Viewer"})
		case "apiKey":
			if project == "" {
				w.WriteHeader(403)
				return
			}
			rows = append(rows, map[string]any{"id": "1c9", "type": page["keyKind"], "accountId": "1a5"})
		case "auditLog":
			if project != "" {
				rows = append(rows, map[string]any{"id": "1al10", "type": "auditLog", "accountId": "1a5", "authenticatedAsAccountId": "1a1",
					"keyId": "1c9", "created": "2026-10-01T12:00:00Z", "eventType": "api.service.update", "decision": "ALLOW", "outcome": "SUCCEEDED"})
			}
		default:
			t.Error("unexpected native source")
			w.WriteHeader(500)
			return
		}
		result := map[string]any{"resourceType": firstNonEmpty(auditString(page, "keyKind"), category), "data": rows, "nextMarker": nil,
			"nativeAuthority": authority, "sourcePageResult": true}
		if mutate != nil {
			if status := mutate(category, page, result); status != 0 {
				w.WriteHeader(status)
				return
			}
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(result)
	})
}

func TestAIAuditPrivateOwnerUsesFourNativeSourcesAndOriginalKeyAuthority(t *testing.T) {
	seen := map[string]int{}
	b := ownerTestBroker(t, sourceFixture(t, func(category string, page, result map[string]any) int { seen[category]++; return 0 }))
	input := ownerInput()
	input.Query.KeyID = "1c9"
	status, body, raw := ownerFrame(t, b, input)
	if status != 200 || body["total"] != float64(1) || strings.Contains(raw, "PRIVATE") || body["payloadPolicy"] != "HUMAN_ONLY_NATIVE_AUDIT_UI" {
		t.Fatal("bounded original aggregation or private boundary failed")
	}
	for _, category := range []string{"project", "account", "apiKey", "auditLog"} {
		if seen[category] == 0 {
			t.Fatal("source not checked:", category)
		}
	}
	row := body["data"].([]any)[0].(map[string]any)
	if row["keyId"] != "1c9" || row["payloadsIncluded"] != false || row["requestPayloadPresence"] != "not_projected" {
		t.Fatal("key query projection changed")
	}
}

func TestAIAuditPrivateSourcesFailClosedOnEveryAuthorityDriftOrDeniedPage(t *testing.T) {
	for _, category := range []string{"project", "account", "apiKey", "auditLog"} {
		for _, failure := range []string{"deny", "actor", "revision", "credential", "crossProject"} {
			t.Run(category+"/"+failure, func(t *testing.T) {
				b := ownerTestBroker(t, sourceFixture(t, func(actual string, page, result map[string]any) int {
					if actual != category {
						return 0
					}
					authority := result["nativeAuthority"].(map[string]any)
					switch failure {
					case "deny":
						return 403
					case "actor":
						authority["actorId"] = "1a2"
					case "revision":
						authority["credentialRevision"] = 4
					case "credential":
						authority["credentialId"] = "1c90"
					case "crossProject":
						authority["accountId"] = "1a99"
					}
					return 0
				}))
				input := ownerInput()
				input.Query.KeyID = "1c9"
				status, body, raw := ownerFrame(t, b, input)
				// Account names are optional in the original owner, but an
				// identity/revision mismatch is never an optional 403.
				if category == "account" && failure == "deny" {
					if status != 200 {
						t.Fatal("original optional account-name behavior changed")
					}
					return
				}
				if status == 200 || body["data"] != nil || strings.Contains(raw, "PRIVATE") {
					t.Fatal("partial aggregate escaped source failure")
				}
			})
		}
	}
}

func TestAIAuditPrivatePaginationRechecksRevisionAndNeverReturnsPartialRows(t *testing.T) {
	calls := 0
	b := ownerTestBroker(t, sourceFixture(t, func(category string, page, result map[string]any) int {
		if category != "auditLog" || page["projectId"] == nil {
			return 0
		}
		calls++
		if calls == 1 {
			result["nextMarker"] = "1al10"
		} else {
			result["nativeAuthority"].(map[string]any)["credentialRevision"] = 4
		}
		return 0
	}))
	status, body, _ := ownerFrame(t, b, ownerInput())
	if status == 200 || body["data"] != nil || calls != 2 {
		t.Fatal("later revision returned partial success")
	}
}

func TestAIAuditPublicGatewayIsFixedTypedAndForwardsOnlyVerifiedResponseMetadata(t *testing.T) {
	calls := 0
	b := ownerTestBroker(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		if r.Method != "POST" || r.URL.Path != "/v2-beta/aiAuditQueries" || r.URL.RawQuery != "" ||
			r.Header.Get("Authorization") != "Basic caller" || r.Header.Get("X-PastureStack-Key-Expected-Revision") != "3" ||
			r.Header.Get("X-Forwarded-User") != "" || r.Header.Get("X-API-Project-ID") != "" {
			t.Error("gateway escaped fixed route/authority")
		}
		w.Header().Set("X-PastureStack-Key-Purpose", "ai-bridge")
		w.Header().Set("X-PastureStack-Key-Revision", "3")
		_, _ = w.Write([]byte(`{"resourceType":"auditLog","data":[]}`))
	}))
	r := httptest.NewRequest("POST", aiAuditQueryPath, strings.NewReader("{}"))
	r.Header.Set("Authorization", "Basic caller")
	r.Header.Set("X-PastureStack-Key-Expected-Revision", "3")
	r.Header.Set("X-Forwarded-User", "forged")
	r.Header.Set("X-API-Project-ID", "foreign")
	w := httptest.NewRecorder()
	b.ServeHTTP(w, r)
	if w.Code != 200 || calls != 1 || w.Header().Get("X-PastureStack-Key-Revision") != "3" {
		t.Fatal("fixed typed gateway failed")
	}
	r = httptest.NewRequest("POST", aiAuditQueryPath+"?url=http://foreign/", strings.NewReader("{}"))
	w = httptest.NewRecorder()
	b.ServeHTTP(w, r)
	if w.Code != 400 || calls != 1 {
		t.Fatal("arbitrary query forwarded")
	}
}

func TestAIAuditCLIRejectsUnverifiedUnknownOrTruncatedPrivateInputWithoutOutput(t *testing.T) {
	for _, input := range []string{`{}`, `{"query":{},"actorId":"1a1","url":"http://foreign/","cookie":"secret"}`,
		`{"query":{},"actorId":"1a1","cookie":"a","authorization":"b"}`, `{"query":{}`, strings.Repeat("x", 65538)} {
		var output bytes.Buffer
		if runAIAuditOwnerCLI(strings.NewReader(input), &output) == 0 || output.Len() != 0 {
			t.Fatal("invalid private input was accepted or disclosed")
		}
	}
}
