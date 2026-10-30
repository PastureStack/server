package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
)

func TestAIAuditCLIUsesOperatorUpstreamForCookieAndOriginalKey(t *testing.T) {
	for _, credential := range []string{"cookie", "key"} {
		t.Run(credential, func(t *testing.T) {
			input := ownerInput()
			if credential == "cookie" {
				input.Cookie = "token=PRIVATE-COOKIE-CANARY"
				input.Authorization, input.CredentialID, input.CredentialKind, input.Revision = "", "", "", 0
			}
			seen := map[string]int{}
			var seenMu sync.Mutex
			upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Method != "POST" || r.URL.Path != "/v2-beta/aiResourceViews" || r.URL.RawQuery != "" ||
					r.Header.Get("Authorization") != input.Authorization || r.Header.Get("Cookie") != input.Cookie ||
					r.Header.Get("X-Forwarded-User") != "" {
					t.Error("configured owner source changed route or private credential binding")
					w.WriteHeader(500)
					return
				}
				if credential == "key" && r.Header.Get("X-PastureStack-Key-Expected-Revision") != "3" ||
					credential == "cookie" && r.Header.Get("X-PastureStack-Key-Expected-Revision") != "" {
					t.Error("source changed credential revision binding")
					w.WriteHeader(500)
					return
				}
				var body map[string]any
				if json.NewDecoder(r.Body).Decode(&body) != nil {
					t.Error("source input invalid")
					w.WriteHeader(500)
					return
				}
				category := auditString(body, "resourceType")
				seenMu.Lock()
				seen[category]++
				seenMu.Unlock()
				page := body["sourcePage"].(map[string]any)
				project := auditString(page, "projectId")
				authority := map[string]any{"actorId": input.ActorID, "accountId": firstNonEmpty(project, input.ActorID)}
				if credential == "key" {
					authority["credentialId"], authority["credentialKind"], authority["credentialRevision"] = input.CredentialID, input.CredentialKind, input.Revision
				}
				rows := []map[string]any{}
				switch category {
				case "project":
					rows = append(rows, map[string]any{"id": "1a5", "type": "project", "name": "Visible"})
				case "account":
					rows = append(rows, map[string]any{"id": "1a1", "type": "account", "name": "Viewer"})
				case "auditLog":
					if project != "" {
						rows = append(rows, map[string]any{"id": "1al10", "type": "auditLog", "accountId": "1a5", "authenticatedAsAccountId": "1a1",
							"created": "2026-10-01T12:00:00Z", "eventType": "api.service.update", "decision": "ALLOW", "outcome": "SUCCEEDED"})
					}
				default:
					t.Error("unrequested source type")
					w.WriteHeader(500)
					return
				}
				w.Header().Set("Content-Type", "application/json")
				_ = json.NewEncoder(w).Encode(map[string]any{"resourceType": category, "data": rows, "nextMarker": nil,
					"nativeAuthority": authority, "sourcePageResult": true})
			}))
			defer upstream.Close()
			t.Setenv("PASTURESTACK_CONSOLE_UPSTREAM_URL", upstream.URL)
			cfg, err := configFromEnvironment()
			if err != nil || cfg.UpstreamURL != upstream.URL {
				t.Fatal("ordinary broker did not use the operator setting")
			}
			private, _ := json.Marshal(input)
			var output bytes.Buffer
			if runAIAuditOwnerCLI(bytes.NewReader(private), &output) != 0 {
				t.Fatal("owner did not return a complete private frame")
			}
			var result struct {
				Status int
				Body   map[string]any
			}
			seenMu.Lock()
			defer seenMu.Unlock()
			if json.Unmarshal(output.Bytes(), &result) != nil || result.Status != 200 || result.Body["total"] != float64(1) ||
				seen["project"] == 0 || seen["auditLog"] == 0 {
				t.Fatalf("CLI did not use the configured source: status=%d sources=%v", result.Status, seen)
			}
			if strings.Contains(output.String(), "PRIVATE") || strings.Contains(output.String(), upstream.URL) {
				t.Fatal("private credential or operator topology escaped the safe output")
			}
		})
	}
}

func TestConsoleUpstreamRetainsDefaultAndRejectsInvalidConfiguredOwner(t *testing.T) {
	t.Setenv("PASTURESTACK_CONSOLE_UPSTREAM_URL", "")
	cfg, err := configFromEnvironment()
	if err != nil || cfg.UpstreamURL != "http://127.0.0.1:8082" {
		t.Fatal("ordinary unset/empty upstream fallback changed")
	}
	t.Setenv("PASTURESTACK_CONSOLE_UPSTREAM_URL", "://invalid")
	private, _ := json.Marshal(ownerInput())
	var output bytes.Buffer
	if runAIAuditOwnerCLI(bytes.NewReader(private), &output) != 2 || output.Len() != 0 {
		t.Fatal("invalid operator topology must not fall back or disclose private diagnostics")
	}
}
