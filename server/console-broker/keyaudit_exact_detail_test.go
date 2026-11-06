package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"strings"
	"testing"
)

func TestKeyAuditExactDetailDoesNotScanHistoryAndKeepsSafeMetadata(t *testing.T) {
	for _, account := range []string{"1a1", "1p1"} {
		t.Run(account, func(t *testing.T) {
			f, server := newKeyAuditFixture(t)
			f.owner, f.accountScoped = account, true
			for i := 0; i <= auditMaximumScanRows; i++ {
				f.records = append(f.records, keyAuditRecord("history"+strconv.Itoa(i), f.keyID, account, "2020-01-01T00:00:00Z"))
			}
			f.records = append(f.records, keyAuditRecord("exact", f.keyID, account, "2020-01-01T00:00:00Z"))
			response := performAuditRequest(t, server, keyAuditQueryPath+"/exact?keyId="+f.keyID+"&timeScope=range&created_gte=2026-01-01T00:00:00Z&created_lte=2026-01-02T00:00:00Z")
			body, _ := io.ReadAll(response.Body)
			response.Body.Close()
			var row map[string]any
			if response.StatusCode != 200 || json.Unmarshal(body, &row) != nil || auditString(row, "id") != "exact" ||
				auditString(row, "accountId") != account || auditString(row, "keyId") != f.keyID || len(f.detailQueries) != 1 || len(f.auditQueries) != 0 {
				t.Fatalf("exact scoped detail did not use one resource read: status=%d details=%d scans=%d", response.StatusCode, len(f.detailQueries), len(f.auditQueries))
			}
			for _, marker := range []string{"must-not-leak", "must-not-export", "Bearer-secret", "session-secret", "jwt-secret", "code-secret", "secretValue", "requestObject", "responseObject"} {
				if strings.Contains(string(body), marker) {
					t.Fatal("detail included a non-whitelisted value")
				}
			}
			listing := performAuditRequest(t, server, keyAuditQueryPath+"?keyId="+f.keyID+"&timeScope=all")
			listing.Body.Close()
			if listing.StatusCode != 422 {
				t.Fatal("collection history scan guard changed")
			}
		})
	}
}

func TestKeyAuditExactDetailKeepsLiveScopePrincipalAndUpstreamFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		edit   func(*keyAuditFixture)
		query  string
		status int
	}{
		{"project-after-personal-404", func(f *keyAuditFixture) { f.records[0]["accountId"] = "1p1" }, "", 200},
		{"admin-broad-by-id-must-not-bypass-account-filter", func(f *keyAuditFixture) { f.detailByIDBroad = true; f.records[0]["accountId"] = "1p1" }, "", 200},
		{"canonical-wire-id-filter", func(f *keyAuditFixture) { f.records[0]["id"] = "1al1008654" }, "", 200},
		{"duplicate-exact-id", func(f *keyAuditFixture) { f.records = append(f.records, cloneAuditRecord(f.records[0])) }, "", 502},
		{"unexpected-next", func(f *keyAuditFixture) { f.detailNext = "/v2-beta/auditlogs?marker=unexpected" }, "", 502},
		{"cross-key", func(f *keyAuditFixture) { f.records[0]["keyId"] = "1c98" }, "", 404},
		{"hidden-project", func(f *keyAuditFixture) { f.records[0]["accountId"] = "1p9" }, "", 404},
		{"caller-project-not-grant", func(f *keyAuditFixture) {}, "&accountId=1p9", 403},
		{"foreign-personal-key", func(f *keyAuditFixture) { f.owner = "1a2" }, "", 403},
		{"membership-revoked", func(f *keyAuditFixture) { f.owner = "1p1"; f.loseProjectAfterKey = true }, "", 403},
		{"key-revoked", func(f *keyAuditFixture) { f.keyStatus = 403 }, "", 403},
		{"principal-after-key", func(f *keyAuditFixture) { f.changeViewerAfterKey = true }, "", 502},
		{"principal-at-detail", func(f *keyAuditFixture) { f.detailViewer = "1a2" }, "", 502},
		{"upstream-401", func(f *keyAuditFixture) { f.detailStatus = 401 }, "", 401},
		{"upstream-403", func(f *keyAuditFixture) { f.detailStatus = 403 }, "", 403},
		{"upstream-outage", func(f *keyAuditFixture) { f.detailStatus = 503 }, "", 502},
		{"no-redirect", func(f *keyAuditFixture) { f.detailRedirect = true }, "", 502},
		{"wrong-event-id", func(f *keyAuditFixture) { f.detailOverride = map[string]any{"id": "other"} }, "", 502},
		{"wrong-native-account", func(f *keyAuditFixture) { f.detailOverride = map[string]any{"accountId": "1p9"} }, "", 502},
	} {
		t.Run(tc.name, func(t *testing.T) {
			f, server := newKeyAuditFixture(t)
			f.records = []map[string]any{keyAuditRecord("exact", f.keyID, "1a1", "2020-01-01T00:00:00Z")}
			tc.edit(f)
			request, _ := http.NewRequest("GET", server.URL+keyAuditQueryPath+"/"+auditString(f.records[0], "id")+"?keyId="+f.keyID+tc.query, nil)
			request.Header.Set("Cookie", "R_SESS=authorized")
			request.Header.Set("X-API-Project-ID", "1p9")
			response, err := server.Client().Do(request)
			if err != nil {
				t.Fatal(err)
			}
			body, _ := io.ReadAll(response.Body)
			response.Body.Close()
			if response.StatusCode != tc.status || len(f.auditQueries) != 0 || f.redirectHits != 0 {
				t.Fatalf("wrong exact-read outcome: status=%d want=%d scans=%d redirectHits=%d", response.StatusCode, tc.status, len(f.auditQueries), f.redirectHits)
			}
			if tc.status != 200 && strings.Contains(string(body), "request-123") {
				t.Fatal("denied event metadata was returned")
			}
		})
	}
}

func TestKeyAuditExactDetailRejectsTypedOwnerWithoutGenericFallback(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("typed owner escaped to generic native GET")
		w.WriteHeader(500)
	}))
	defer upstream.Close()
	target, _ := url.Parse(upstream.URL)
	broker := &broker{upstreamURL: target}
	ctx := context.WithValue(context.Background(), aiAuditOwnerContext{}, &aiAuditOwnerState{})
	record, err := broker.fetchKeyAuditDetail(ctx, httptest.NewRequest("GET", keyAuditQueryPath+"/exact?keyId=1c99", nil), auditQuery{}, "exact")
	if err == nil || record != nil {
		t.Fatal("typed owner obtained normal human detail")
	}
	status, ok := err.(*auditHTTPError)
	if !ok || status.Status != 403 {
		t.Fatal("typed owner did not fail closed")
	}
}
