package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

const keyAuditQueryPath = "/v2-beta/pasturestack/key-audit-logs"

var keyAuditIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_-]{0,159}$`)

func isKeyAuditPath(path string) bool {
	return path == keyAuditQueryPath || strings.HasPrefix(path, keyAuditQueryPath+"/")
}

func (b *broker) serveKeyAudit(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writer.Header().Set("Allow", "GET")
		writeJSONError(writer, http.StatusMethodNotAllowed, "method_not_allowed", "Method not allowed")
		return
	}
	keyID := request.URL.Query().Get("keyId")
	if !keyAuditIDPattern.MatchString(keyID) {
		writeJSONError(writer, http.StatusBadRequest, "key_id_required", "A valid API key identifier is required")
		return
	}
	values := request.URL.Query()
	// The generic audit contract uses timeScope (v518). Accept the early
	// Key UI alias only on this new route, without changing generic parsing.
	if alias := strings.ToLower(values.Get("timescope")); alias != "" {
		if alias != "all" && alias != "range" {
			writeJSONError(writer, http.StatusBadRequest, "invalid_timescope", "Audit time scope must be all or range")
			return
		}
		if canonical := values.Get("timeScope"); canonical != "" && (alias != "all" || canonical != "all") {
			writeJSONError(writer, http.StatusBadRequest, "conflicting_time_scope", "Conflicting audit time scopes")
			return
		}
		if alias == "all" {
			values.Set("timeScope", "all")
		}
		values.Del("timescope")
	}
	detailID := strings.TrimPrefix(request.URL.Path, keyAuditQueryPath)
	if detailID != "" {
		detailID = strings.TrimPrefix(detailID, "/")
		if !keyAuditIDPattern.MatchString(detailID) {
			writeJSONError(writer, http.StatusNotFound, "key_audit_not_found", "The API key audit event is not available")
			return
		}
		// A detail is still scoped by live permissions and keyId, independent
		// of a UI's selected time range or pagination.
		values.Set("timeScope", "all")
		for _, name := range []string{"created_gte", "created_lte", "createdFrom", "createdTo"} {
			values.Del(name)
		}
	}
	query, err := parseAuditQuery(values, time.Now().UTC())
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}
	owner, viewer, err := b.fetchKeyAuditAuthority(request.Context(), request, keyID)
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}
	query.KeyID, query.KeyOwnerAccountID, query.ViewerAccountID = keyID, owner, viewer
	result, err := b.runAuditQuery(request.Context(), request, query)
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}
	if detailID != "" {
		for _, record := range result.Records {
			if auditString(record, "id") == detailID {
				writer.Header().Set("Content-Type", "application/json; charset=utf-8")
				writer.Header().Set("Cache-Control", "no-store")
				writer.Header().Set("X-Content-Type-Options", "nosniff")
				_ = json.NewEncoder(writer).Encode(record)
				return
			}
		}
		writeJSONError(writer, http.StatusNotFound, "key_audit_not_found", "The API key audit event is not available under your current permissions")
		return
	}
	writeAuditCollection(writer, request, query, result)
}

// Credential visibility and principal identity are determined by the Engine
// for the current session on every query. No browser identity is trusted.
func (b *broker) fetchKeyAuditAuthority(ctx context.Context, incoming *http.Request, keyID string) (string, string, error) {
	target := *b.upstreamURL
	client := &http.Client{Timeout: 20 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error {
		return errors.New("API key authority redirects are not allowed")
	}}
	for index, kind := range []string{"apiKey", "apiKeyRestricted"} {
		target.Path, target.RawPath, target.RawQuery, target.Fragment = "/v2-beta/"+strings.ToLower(kind)+"/"+keyID, "", "", ""
		request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
		if err != nil {
			return "", "", err
		}
		copyAuditAuthHeaders(request.Header, incoming.Header)
		request.Header.Set("Accept", "application/json")
		response, err := client.Do(request)
		if err != nil {
			return "", "", &auditHTTPError{Status: http.StatusBadGateway, Code: "key_audit_unavailable", Message: "API key permissions could not be verified"}
		}
		if response.StatusCode != http.StatusOK {
			_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 64*1024))
			response.Body.Close()
			if response.StatusCode == http.StatusNotFound && index == 0 {
				continue
			}
			status, code := http.StatusBadGateway, "key_audit_unavailable"
			if response.StatusCode == http.StatusUnauthorized {
				status, code = http.StatusUnauthorized, "key_audit_session_expired"
			} else if response.StatusCode == http.StatusForbidden || response.StatusCode == http.StatusNotFound {
				status, code = http.StatusForbidden, "key_audit_access_lost"
			}
			return "", "", &auditHTTPError{Status: status, Code: code, Message: "The API key is no longer available under your current permissions"}
		}
		var key map[string]any
		decoder := json.NewDecoder(io.LimitReader(response.Body, 1024*1024))
		decodeErr := decoder.Decode(&key)
		response.Body.Close()
		if decodeErr != nil || auditString(key, "id") != keyID || !strings.EqualFold(auditString(key, "type"), kind) {
			return "", "", &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_key_authority", Message: "API key service returned an invalid permission response"}
		}
		owner, viewer := auditString(key, "accountId"), response.Header.Get("X-API-USER-ID")
		if !keyAuditIDPattern.MatchString(owner) || !keyAuditIDPattern.MatchString(viewer) {
			return "", "", &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_key_authority", Message: "API key owner and current user could not be verified"}
		}
		return owner, viewer, nil
	}
	return "", "", &auditHTTPError{Status: http.StatusForbidden, Code: "key_audit_access_lost", Message: "The API key is no longer available under your current permissions"}
}

func keyAuditMetadataString(record map[string]any, field string) string {
	if value := auditString(record, field); value != "" {
		return value
	}
	if data, ok := record["data"].(map[string]any); ok {
		if fields, ok := data["fields"].(map[string]any); ok {
			return auditString(fields, field)
		}
	}
	return ""
}

func safeKeyAuditRecord(record map[string]any) map[string]any {
	result := make(map[string]any)
	for _, field := range []string{
		"type", "id", "created", "accountId", "authenticatedAsAccountId", "authenticatedAsIdentityId",
		"authType", "eventType", "resourceType", "resourceId", "clientIp", "runtime",
		"eventId", "keyId", "decision", "outcome", "httpStatus", "responseCode", "requestId", "actor",
		"targetType", "targetId", "operation", "policyRevision", "reason", "phase", "preview", "processId", "processName",
		"hostUuid", "failureCode",
	} {
		if value, present := record[field]; present {
			switch value.(type) {
			case string, bool, json.Number, float64, int, int64:
				result[field] = value
			}
		} else if value := keyAuditMetadataString(record, field); value != "" {
			result[field] = value
		}
	}
	return result
}
