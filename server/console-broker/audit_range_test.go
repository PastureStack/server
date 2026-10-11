package main

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"testing"
	"time"
)

func TestParseAuditQueryExplicitRangeUsesExistingBoundedWindow(t *testing.T) {
	now := time.Date(2026, 10, 9, 10, 20, 0, 0, time.UTC)
	cases := []struct {
		name, from, to, code string
		status               int
	}{
		{name: "native UI range", from: "2026-10-08T10:20:00Z", to: "2026-10-09T10:20:00Z"},
		{name: "timezone and subsecond", from: "2026-10-08T18:20:00.123+08:00", to: "2026-10-09T18:20:00.123+08:00"},
		{name: "maximum window", from: "2025-10-08T10:20:00Z", to: "2026-10-09T10:20:00Z"},
		{name: "both missing", code: "incomplete_time_range", status: http.StatusBadRequest},
		{name: "start missing", to: "2026-10-09T10:20:00Z", code: "incomplete_time_range", status: http.StatusBadRequest},
		{name: "end missing", from: "2026-10-08T10:20:00Z", code: "incomplete_time_range", status: http.StatusBadRequest},
		{name: "timezone missing", from: "2026-10-08T10:20:00", to: "2026-10-09T10:20:00Z", code: "invalid_time_range", status: http.StatusBadRequest},
		{name: "zero width", from: "2026-10-09T10:20:00Z", to: "2026-10-09T10:20:00Z", code: "invalid_time_range", status: http.StatusBadRequest},
		{name: "reversed", from: "2026-10-09T10:20:00Z", to: "2026-10-08T10:20:00Z", code: "invalid_time_range", status: http.StatusBadRequest},
		{name: "maximum exceeded", from: "2025-10-08T10:19:59Z", to: "2026-10-09T10:20:00Z", code: "time_range_too_large", status: http.StatusUnprocessableEntity},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			query, err := parseAuditQuery(url.Values{"timeScope": {"range"}, "created_gte": {tc.from}, "created_lte": {tc.to}}, now)
			if tc.code != "" {
				var failure *auditHTTPError
				if !errors.As(err, &failure) || failure.Status != tc.status || failure.Code != tc.code {
					t.Fatalf("expected %d %s, got %v", tc.status, tc.code, err)
				}
				return
			}
			from, _ := time.Parse(time.RFC3339Nano, tc.from)
			to, _ := time.Parse(time.RFC3339Nano, tc.to)
			if err != nil || query.AllTime || !query.From.Equal(from) || !query.To.Equal(to) || query.From.Location() != time.UTC || query.To.Location() != time.UTC {
				t.Fatalf("explicit range changed the bounded UTC window: %#v %v", query, err)
			}
		})
	}
}

func TestKeyAuditNativeRangeFiltersBeforeCountAndKeepsOwnerIsolation(t *testing.T) {
	fixture, server := newKeyAuditFixture(t)
	fixture.accountScoped = true
	fixture.records = []map[string]any{
		keyAuditRecord("before", "1a99", "1p1", "2026-10-08T10:19:59Z"),
		keyAuditRecord("start", "1a99", "1a1", "2026-10-08T10:20:00Z"),
		keyAuditRecord("middle", "1a99", "1p1", "2026-10-08T12:00:00Z"),
		keyAuditRecord("end", "1a99", "1p1", "2026-10-09T10:20:00Z"),
		keyAuditRecord("foreign", "1a98", "1p1", "2026-10-08T12:00:00Z"),
		keyAuditRecord("hidden", "1a99", "1p9", "2026-10-08T12:00:00Z"),
	}
	query := "?keyId=1a99&timeScope=range&created_gte=2026-10-08T10%3A20%3A00Z&created_lte=2026-10-09T10%3A20%3A00Z"
	response := performAuditRequest(t, server, keyAuditQueryPath+query+"&limit=1&offset=1&order=asc")
	var payload auditCollection
	err := json.NewDecoder(response.Body).Decode(&payload)
	response.Body.Close()
	if response.StatusCode != http.StatusOK || err != nil || payload.Pagination["total"] != float64(2) || len(payload.Data) != 1 || auditString(payload.Data[0], "id") != "middle" {
		t.Fatalf("native range did not apply [from,to), Key, and live owner scope before pagination: %d %#v %v", response.StatusCode, payload, err)
	}
	for _, values := range fixture.auditQueries {
		if values.Get("created_gte") != "2026-10-08T10:20:00Z" {
			t.Fatalf("range lower boundary missing from live account-scoped scan: %#v", values)
		}
	}
	// Detail remains independent of list time boundaries, but not of Key or RBAC.
	for _, tc := range []struct {
		id     string
		status int
	}{{"before", http.StatusOK}, {"foreign", http.StatusNotFound}, {"hidden", http.StatusNotFound}} {
		detail := performAuditRequest(t, server, keyAuditQueryPath+"/"+tc.id+query)
		detail.Body.Close()
		if detail.StatusCode != tc.status {
			t.Fatalf("range detail %s escaped its independent live scope: %d", tc.id, detail.StatusCode)
		}
	}
	fixture.mu.Lock()
	fixture.owner = "1a2"
	scans := len(fixture.auditQueries)
	fixture.mu.Unlock()
	foreign := performAuditRequest(t, server, keyAuditQueryPath+query)
	foreign.Body.Close()
	if foreign.StatusCode != http.StatusForbidden || len(fixture.auditQueries) != scans {
		t.Fatalf("range bypassed foreign personal-Key ownership: %d", foreign.StatusCode)
	}
}
