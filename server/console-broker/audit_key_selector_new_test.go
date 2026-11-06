package main

import (
	"context"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"reflect"
	"testing"
	"time"
)

func selectorTestBroker(t *testing.T, fixture *auditUpstreamFixture) *broker {
	t.Helper()
	b, err := newBroker(brokerConfig{UpstreamURL: fixture.server.URL, SessionDialURL: fixture.server.URL, MaxSessions: 1,
		ReplayBytes: 65536, ActiveTTL: time.Hour, HistoryTTL: time.Hour, CleanupInterval: time.Hour}, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(b.close)
	return b
}

func TestKeyAuditQueryForwardsVerifiedSelectedKeyToEveryNativeContext(t *testing.T) {
	fixture := newAuditUpstreamFixture(t)
	fixture.viewerAccountID = "1a1"
	fixture.keyIDSelector = true
	fixture.auditRecords = []map[string]any{}
	b := selectorTestBroker(t, fixture)
	incoming := httptest.NewRequest(http.MethodGet, auditQueryPath, nil)
	incoming.Header.Set("Cookie", fixture.allowedCookie)
	_, err := b.runAuditQuery(context.Background(), incoming, auditQuery{AllTime: true, KeyID: "1c8", KeyOwnerAccountID: "1a1", ViewerAccountID: "1a1", Limit: 25})
	if err != nil {
		t.Fatal(err)
	}
	fixture.mu.Lock()
	defer fixture.mu.Unlock()
	if len(fixture.auditQueries) == 0 {
		t.Fatal("native reads were not observed")
	}
	for _, values := range fixture.auditQueries {
		if !reflect.DeepEqual(values["keyId"], []string{"1c8"}) {
			t.Fatalf("selected key missing from native query: %v", values)
		}
	}
}

func TestAuditPaginationPinsSelectedKeyAndExplicitAbsenceAgainstNext(t *testing.T) {
	for _, tc := range []struct {
		name string
		key  []string
		next string
	}{
		{"present omitted by next", []string{"1c8"}, "page=2"},
		{"present changed or duplicated by next", []string{"1c8"}, "page=2&keyId=1c9&keyId=1c10"},
		{"absent cannot be injected", nil, "page=2&keyId=1c9"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			fixture := newAuditUpstreamFixture(t)
			fixture.nextAuditQuery = tc.next
			fixture.auditRecords = []map[string]any{auditTestRecord("first", "2026-10-01T01:00:00Z", "1p1", "1a1", "read", "TokenAuth", "safe")}
			fixture.secondPage = []map[string]any{auditTestRecord("second", "2026-10-01T00:00:00Z", "1p1", "1a1", "read", "TokenAuth", "safe")}
			b := selectorTestBroker(t, fixture)
			values := url.Values{"limit": {"1000"}, "sort": {"id"}, "order": {"desc"}}
			if tc.key != nil {
				values["keyId"] = append([]string(nil), tc.key...)
			}
			before := values.Encode()
			incoming := httptest.NewRequest(http.MethodGet, auditQueryPath, nil)
			incoming.Header.Set("Cookie", fixture.allowedCookie)
			records, err := b.fetchAllAuditLogsForViewer(context.Background(), incoming, values, "")
			if err != nil || len(records) != 2 {
				t.Fatalf("two native pages required: %v", err)
			}
			if values.Encode() != before {
				t.Fatal("input mutated")
			}
			fixture.mu.Lock()
			defer fixture.mu.Unlock()
			if len(fixture.auditQueries) != 2 || fixture.auditQueries[1].Get("page") != "2" || !reflect.DeepEqual(fixture.auditQueries[1]["keyId"], tc.key) {
				t.Fatalf("next changed the fixed key selector: %v", fixture.auditQueries)
			}
		})
	}
}

func TestAIAuditSourceForwardsOnlyOneAuditCollectionKeyAndRetainsAuthority(t *testing.T) {
	var pages []map[string]any
	drift := false
	b := ownerTestBroker(t, sourceFixture(t, func(category string, page, result map[string]any) int {
		copied := map[string]any{}
		for key, value := range page {
			copied[key] = value
		}
		pages = append(pages, copied)
		if category == "auditLog" {
			result["nextMarker"] = "1al10"
		}
		if drift {
			result["nativeAuthority"].(map[string]any)["credentialRevision"] = 4
		}
		return 0
	}))
	input := ownerInput()
	ctx := context.WithValue(context.Background(), aiAuditOwnerContext{}, &aiAuditOwnerState{input: input})
	incoming := httptest.NewRequest(http.MethodGet, auditQueryPath, nil)
	collection, err := b.fetchAIAuditSource(ctx, incoming, "auditLog", "", "1a5", "", url.Values{"keyId": {"1c9"}})
	if err != nil {
		t.Fatal(err)
	}
	if pages[0]["keyId"] != "1c9" || input.CredentialID != "1c8" {
		t.Fatal("selected audit key conflated with original credential")
	}
	next, _ := url.Parse(collection.Pagination["next"].(string))
	if next.Query().Get("keyId") != "1c9" {
		t.Fatal("typed marker lost selected key")
	}
	count := len(pages)
	for _, tc := range []struct {
		category, id string
		values       url.Values
	}{
		{"account", "", url.Values{"keyId": {"1c9"}}}, {"auditLog", "1al10", url.Values{"keyId": {"1c9"}}},
		{"auditLog", "", url.Values{"keyId": {"1c9", "1c10"}}}, {"auditLog", "", url.Values{"keyId": {""}}},
		{"auditLog", "", url.Values{"keyId": {"../1c9"}}},
	} {
		if _, err = b.fetchAIAuditSource(ctx, incoming, tc.category, tc.id, "1a5", "", tc.values); err == nil {
			t.Fatal("non-closed key selector accepted")
		}
	}
	if len(pages) != count {
		t.Fatal("invalid key selector reached native transport")
	}
	if _, err = b.fetchAIAuditSource(ctx, incoming, "project", "", "", "", url.Values{}); err != nil {
		t.Fatal("key-absent source changed", err)
	}
	if _, present := pages[len(pages)-1]["keyId"]; present {
		t.Fatal("selector invented for absent source")
	}
	drift = true
	if _, err = b.fetchAIAuditSource(ctx, incoming, "auditLog", "", "1a5", "", url.Values{"keyId": {"1c9"}}); err == nil {
		t.Fatal("selector bypassed credential revision")
	}
}
