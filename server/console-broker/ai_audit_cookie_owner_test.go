package main

import (
	"encoding/json"
	"net/http"
	"testing"
)

func TestAIAuditCookieOwnerUsesSameSafeSourcesWithoutBorrowingAnyKey(t *testing.T) {
	foreignKey := false
	b := ownerTestBroker(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" || r.URL.Path != "/v2-beta/aiResourceViews" || r.Header.Get("Cookie") != "R_SESS=PRIVATE" ||
			r.Header.Get("Authorization") != "" || r.Header.Get("X-PastureStack-Key-Expected-Revision") != "" {
			t.Error("cookie authority changed")
			w.WriteHeader(500)
			return
		}
		var input map[string]any
		_ = json.NewDecoder(r.Body).Decode(&input)
		category := auditString(input, "resourceType")
		page := input["sourcePage"].(map[string]any)
		project := auditString(page, "projectId")
		authority := map[string]any{"actorId": "1a1", "accountId": firstNonEmpty(project, "1a1")}
		if foreignKey {
			authority["credentialId"] = "1c99"
		}
		rows := []map[string]any{}
		if category == "project" {
			rows = append(rows, map[string]any{"id": "1a5", "type": "project"})
		}
		if category == "auditLog" && project != "" {
			rows = append(rows, map[string]any{"id": "1al10", "accountId": "1a5", "created": "2026-10-01T12:00:00Z"})
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"resourceType": category, "data": rows, "nextMarker": nil,
			"sourcePageResult": true, "nativeAuthority": authority})
	}))
	input := ownerInput()
	input.Authorization = ""
	input.Cookie = "R_SESS=PRIVATE"
	input.CredentialID = ""
	input.CredentialKind = ""
	input.Revision = 0
	status, body, _ := ownerFrame(t, b, input)
	if status != 200 || body["total"] != float64(1) {
		t.Fatal("cookie metadata workflow failed")
	}
	foreignKey = true
	status, body, _ = ownerFrame(t, b, input)
	if status == 200 || body["data"] != nil {
		t.Fatal("cookie query borrowed another credential")
	}
}
