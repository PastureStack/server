package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"reflect"
	"strconv"
	"testing"
)

func selectorCapabilitySchema(supported bool) map[string]any {
	var schema map[string]any
	if json.Unmarshal([]byte("{\"id\":\"auditLog\",\"type\":\"schema\",\"links\":{\"self\":null,\"collection\":null},\"actions\":{},\"fields\":{},\"pluralName\":\"auditLogs\",\"resourceFields\":{\"keyId\":{\"type\":\"string\",\"description\":null,\"create\":false,\"update\":false,\"readOnCreateOnly\":false}},\"collectionFilters\":{\"keyId\":{\"modifiers\":[\"eq\"]}},\"includeableLinks\":[],\"resourceActions\":{},\"collectionActions\":{},\"collectionFields\":{},\"collectionMethods\":[\"GET\"],\"resourceMethods\":[\"GET\"],\"baseType\":\"schema\"}"), &schema) != nil {
		panic("invalid pinned native schema fixture")
	}
	if !supported {
		delete(schema["collectionFilters"].(map[string]any), "keyId")
	}
	return schema
}

func TestAuditKeySelectorCapabilityTrueFalseKeepsExactLocalFilterAndBound(t *testing.T) {
	for _, supported := range []bool{true, false} {
		t.Run(strconv.FormatBool(supported), func(t *testing.T) {
			fixture := newAuditUpstreamFixture(t)
			fixture.viewerAccountID, fixture.keyIDSelector = "1a1", supported
			fixture.auditRecords = []map[string]any{
				keyAuditRecord("selected", "1c8", "1a1", "2026-10-01T12:00:00Z"),
				keyAuditRecord("foreign", "1c9", "1a1", "2026-10-01T12:00:00Z"),
			}
			b := selectorTestBroker(t, fixture)
			incoming := httptest.NewRequest("GET", auditQueryPath, nil)
			incoming.Header.Set("Cookie", fixture.allowedCookie)
			result, err := b.runAuditQuery(context.Background(), incoming, auditQuery{AllTime: true, KeyID: "1c8", KeyOwnerAccountID: "1a1", ViewerAccountID: "1a1", Limit: 25})
			if err != nil || result.Total != 1 || len(result.Records) != 1 || auditString(result.Records[0], "id") != "selected" || auditMaximumScanRows != 20000 {
				t.Fatal("capability changed exact local filtering or original bound", err)
			}
			if len(fixture.auditQueries) != 3 {
				t.Fatal("native account contexts changed")
			}
			for _, values := range fixture.auditQueries {
				if supported && !reflect.DeepEqual(values["keyId"], []string{"1c8"}) || !supported && values.Has("keyId") {
					t.Fatal("selector does not follow verified capability")
				}
			}
		})
	}
}

func TestAuditKeySelectorCapabilityErrorsNeverReadOrRetryWithoutSelector(t *testing.T) {
	for _, failure := range []string{"401", "403", "redirect", "malformed", "actor", "schema", "no-get", "field-type", "hidden", "read-on-create", "transform", "filter-null", "filter-array", "filter-extra", "native-422"} {
		t.Run(failure, func(t *testing.T) {
			schemaCalls, rowCalls, redirectHits := 0, 0, 0
			b := ownerTestBroker(t, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Method != "GET" || r.Header.Get("Cookie") != "R_SESS=capability" || r.Header.Get("Authorization") != "Basic ORIGINAL" || r.URL.Path == "/v2-beta/schemas/auditLog" && (r.Header.Get("X-PastureStack-Key-Expected-Revision") != "7" || r.URL.RawQuery != "") {
					t.Error("schema read escaped original credential or fixed path")
					w.WriteHeader(500)
					return
				}
				w.Header().Set("X-API-USER-ID", "1a1")
				switch r.URL.Path {
				case "/v2-beta/schemas/auditLog":
					schemaCalls++
					if failure == "401" || failure == "403" {
						status, _ := strconv.Atoi(failure)
						w.WriteHeader(status)
						return
					}
					if failure == "redirect" {
						http.Redirect(w, r, "/redirected", 302)
						return
					}
					if failure == "malformed" {
						_, _ = w.Write([]byte("{"))
						return
					}
					schema := selectorCapabilitySchema(true)
					field := schema["resourceFields"].(map[string]any)["keyId"].(map[string]any)
					filters := schema["collectionFilters"].(map[string]any)
					switch failure {
					case "actor":
						w.Header().Set("X-API-USER-ID", "1a2")
					case "schema":
						schema["id"] = "service"
					case "no-get":
						schema["collectionMethods"] = []string{"POST"}
					case "field-type":
						field["type"] = "secret"
					case "hidden":
						delete(schema["resourceFields"].(map[string]any), "keyId")
					case "read-on-create":
						field["readOnCreateOnly"] = true
					case "transform":
						field["transform"] = "hidden"
					case "filter-null":
						filters["keyId"] = nil
					case "filter-array":
						filters["keyId"] = []string{"eq"}
					case "filter-extra":
						filters["keyId"] = map[string]any{"modifiers": []string{"eq", "ne"}}
					}
					_ = json.NewEncoder(w).Encode(schema)
				case "/v2-beta/auditlogs":
					rowCalls++
					if !reflect.DeepEqual(r.URL.Query()["keyId"], []string{"1c8"}) {
						t.Error("native selector dropped")
					}
					w.WriteHeader(422)
				default:
					redirectHits++
					w.WriteHeader(500)
				}
			}))
			incoming := httptest.NewRequest("GET", auditQueryPath, nil)
			incoming.Header.Set("Cookie", "R_SESS=capability")
			incoming.Header.Set("Authorization", "Basic ORIGINAL")
			incoming.Header.Set("X-PastureStack-Key-Expected-Revision", "7")
			supported, err := b.auditKeySelectorCapability(context.Background(), incoming, "1a1")
			if failure == "native-422" {
				if err != nil || !supported {
					t.Fatal("valid capability rejected", err)
				}
				_, err = b.fetchAllAuditLogsForViewer(context.Background(), incoming, url.Values{"keyId": {"1c8"}}, "1a1")
			}
			if err == nil || schemaCalls != 1 || redirectHits != 0 || rowCalls != map[bool]int{true: 1, false: 0}[failure == "native-422"] {
				t.Fatal("capability failure read rows or selector error retried")
			}
			var upstream *auditHTTPError
			if !errors.As(err, &upstream) || failure == "401" && upstream.Status != 401 || failure == "403" && upstream.Status != 403 {
				t.Fatal("authentication failure classification changed")
			}
		})
	}
}

func TestAIAuditCapabilityUsesOnlyFixedTypedSourceAndExactAuthority(t *testing.T) {
	for _, outcome := range []string{"true", "false", "missing", "null", "string", "extra", "rows", "marker", "missing-marker", "actor", "account", "revision", "403", "redirect", "native-422"} {
		t.Run(outcome, func(t *testing.T) {
			capCalls, rowCalls := 0, 0
			b := ownerTestBroker(t, sourceFixture(t, func(category string, page, result map[string]any) int {
				if page["capabilitiesOnly"] != true {
					rowCalls++
					if outcome != "native-422" || category != "auditLog" || page["keyId"] != "1c9" {
						t.Error("unexpected typed row read")
					}
					return 422
				}
				capCalls++
				if category != "auditLog" || len(page) != 1 {
					t.Error("capability request mixed source fields")
				}
				result["nativeCapabilities"] = map[string]any{"keyIdSelector": true}
				switch outcome {
				case "false":
					result["nativeCapabilities"] = map[string]any{"keyIdSelector": false}
				case "missing":
					delete(result, "nativeCapabilities")
				case "null":
					result["nativeCapabilities"] = map[string]any{"keyIdSelector": nil}
				case "string":
					result["nativeCapabilities"] = map[string]any{"keyIdSelector": "true"}
				case "extra":
					result["nativeCapabilities"] = map[string]any{"keyIdSelector": true, "arbitrary": true}
				case "rows":
					result["data"] = []map[string]any{{"id": "1al10"}}
				case "marker":
					result["nextMarker"] = "1al10"
				case "missing-marker":
					delete(result, "nextMarker")
				case "actor":
					result["nativeAuthority"].(map[string]any)["actorId"] = "1a2"
				case "account":
					result["nativeAuthority"].(map[string]any)["accountId"] = "1a5"
				case "revision":
					result["nativeAuthority"].(map[string]any)["credentialRevision"] = 4
				case "403":
					return 403
				case "redirect":
					return 302
				}
				return 0
			}))
			ctx := context.WithValue(context.Background(), aiAuditOwnerContext{}, &aiAuditOwnerState{input: ownerInput()})
			incoming := httptest.NewRequest("GET", auditQueryPath, nil)
			supported, err := b.auditKeySelectorCapability(ctx, incoming, "1a1")
			valid := outcome == "true" || outcome == "false" || outcome == "native-422"
			if (err == nil) != valid || valid && supported != (outcome != "false") || capCalls != 1 || rowCalls != 0 {
				t.Fatal("typed capability or authority contract changed", err)
			}
			if outcome == "native-422" {
				_, err = b.fetchAllAuditLogsForViewer(ctx, incoming, url.Values{"keyId": {"1c9"}}, "1a1")
				if err == nil || rowCalls != 1 || capCalls != 1 {
					t.Fatal("typed selector failure retried")
				}
			}
			calls := capCalls + rowCalls
			for _, values := range []url.Values{{"capabilitiesOnly": {"true"}, "keyId": {"1c9"}}, {"capabilitiesOnly": {"true"}, "limit": {"1"}}, {"capabilitiesOnly": {"false"}}, {"capabilitiesOnly": {"true", "true"}}} {
				if _, err := b.fetchAIAuditSource(ctx, incoming, "auditLog", "", "", "", values); err == nil {
					t.Fatal("mixed capability page accepted")
				}
			}
			for _, source := range []struct{ category, id, project, kind string }{{"account", "", "", ""}, {"auditLog", "1al10", "", ""}, {"auditLog", "", "1a5", ""}, {"auditLog", "", "", "apiKey"}} {
				if _, err := b.fetchAIAuditSource(ctx, incoming, source.category, source.id, source.project, source.kind, url.Values{"capabilitiesOnly": {"true"}}); err == nil {
					t.Fatal("capability escaped fixed audit source")
				}
			}
			if _, err := b.fetchAuditPagePolicy(ctx, incoming, "/v2-beta/schemas/auditLog", url.Values{"keyId": {"1c9"}}, true); err == nil || capCalls+rowCalls != calls {
				t.Fatal("invalid capability reached transport")
			}
		})
	}
}
