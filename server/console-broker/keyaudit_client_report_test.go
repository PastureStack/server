package main

import (
	"reflect"
	"testing"
)

func TestClientToolReportHumanKeyProjectionKeepsOnlyBoundedCanonicalEvidence(t *testing.T) {
	want := map[string]any{"id": "1al42", "resourceType": "aiToolCallEvent", "keyId": "1c99", "phase": "client-report",
		"decision": "NOT_EVALUATED", "outcome": "REPORTED", "evidenceSource": "client_reported",
		"clientReportedCommand": "preview_resource_change", "clientReportedPhase": "result",
		"clientReportedStatus": "needs_user", "clientReportedReason": "NEEDS_USER", "clientReportedReasonDetail": "BRIDGE_PROJECT_BINDING_REQUIRED"}
	for _, nested := range []bool{false, true} {
		record := make(map[string]any)
		for k, v := range want {
			record[k] = v
		}
		record["requestObject"] = map[string]any{"secret": "PRIVATE"}
		record["responseObject"] = "PRIVATE"
		if nested {
			fields := make(map[string]any)
			for k, v := range record {
				if k != "id" && k != "resourceType" {
					fields[k] = v
					delete(record, k)
				}
			}
			record["data"] = map[string]any{"fields": fields}
		}
		got := safeKeyAuditRecord(record, "1c99")
		if !reflect.DeepEqual(got, want) {
			t.Fatalf("bounded canonical projection differs: %#v", got)
		}
		ai := safeAIAuditRecord(record, "1c99")
		for _, field := range []string{"evidenceSource", "clientReportedCommand", "clientReportedPhase", "clientReportedStatus", "clientReportedReason", "clientReportedReasonDetail", "requestObject", "responseObject"} {
			if _, present := ai[field]; present {
				t.Fatalf("existing AI-facing contract expanded: %s", field)
			}
		}
	}
}

func TestClientToolReportProjectionNeverTurnsForgedOrPlatformValuesIntoClientFacts(t *testing.T) {
	base := map[string]any{"resourceType": "aiToolCallEvent", "keyId": "1c99", "phase": "client-report",
		"decision": "NOT_EVALUATED", "outcome": "REPORTED", "evidenceSource": "client_reported",
		"clientReportedCommand": "preview_resource_change", "clientReportedPhase": "result",
		"clientReportedStatus": "needs_user", "clientReportedReason": "NEEDS_USER", "clientReportedReasonDetail": "BRIDGE_PROJECT_BINDING_REQUIRED"}
	for field, value := range map[string]any{"resourceType": "service", "phase": "decision", "decision": "DENY", "outcome": "DENIED", "evidenceSource": "server_authoritative"} {
		record := make(map[string]any)
		for k, v := range base {
			record[k] = v
		}
		record[field] = value
		got := safeKeyAuditRecord(record, "1c99")
		for _, key := range []string{"evidenceSource", "clientReportedCommand", "clientReportedPhase", "clientReportedStatus", "clientReportedReason", "clientReportedReasonDetail"} {
			if _, present := got[key]; present {
				t.Fatalf("unqualified evidence survived %s", field)
			}
		}
		if got["decision"] != record["decision"] || got["outcome"] != record["outcome"] {
			t.Fatal("platform decision was rewritten")
		}
	}
	for field, value := range map[string]any{"clientReportedCommand": "get_service", "clientReportedPhase": "start", "clientReportedStatus": "succeeded", "clientReportedReason": "FORBIDDEN", "clientReportedReasonDetail": "PRIVATE"} {
		record := make(map[string]any)
		for k, v := range base {
			record[k] = v
		}
		record[field] = value
		got := safeKeyAuditRecord(record, "1c99")
		if _, present := got["clientReportedReasonDetail"]; present {
			t.Fatalf("specific detail survived wrong tuple %s", field)
		}
	}
	for _, value := range []any{"PRIVATE", "NEEDS_USER PRIVATE", map[string]any{"secret": "PRIVATE"}, []string{"PRIVATE"}, nil} {
		record := make(map[string]any)
		for k, v := range base {
			record[k] = v
		}
		record["clientReportedReason"] = value
		got := safeKeyAuditRecord(record, "1c99")
		if _, present := got["clientReportedReason"]; present {
			t.Fatal("unbounded reason survived")
		}
		if _, present := got["clientReportedReasonDetail"]; present {
			t.Fatal("detail survived invalid reason")
		}
	}
	legacy := map[string]any{"resourceType": "service", "keyId": "1c99", "decision": "ALLOW", "outcome": "SUCCEEDED", "reason": "DONE"}
	if !reflect.DeepEqual(safeKeyAuditRecord(legacy, "1c99"), legacy) {
		t.Fatal("unrelated platform projection changed")
	}
}
