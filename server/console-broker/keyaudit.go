package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"sort"
	"strings"
	"time"
)

const keyAuditQueryPath = "/v2-beta/pasturestack/key-audit-logs"

var keyAuditIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_-]{0,159}$`)

func (b *broker) fetchKeyAuditLogs(ctx context.Context, incoming *http.Request, query auditQuery,
	allowedProjects map[string]string, baseValues url.Values) ([]map[string]any, error) {
	// Only Engine-proven live memberships select project contexts. Never
	// accept a client project header, inferred Key owner or payload as a grant.
	contexts := make([]string, 0, len(allowedProjects)+1)
	if query.EnvironmentID == "" {
		contexts = append(contexts, "") // current viewer's personal account
	}
	for projectID := range allowedProjects {
		if !keyAuditIDPattern.MatchString(projectID) {
			return nil, &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_key_audit_scope", Message: "Current environment permissions could not be verified"}
		}
		if query.EnvironmentID == "" || projectID == query.EnvironmentID {
			contexts = append(contexts, projectID)
		}
	}
	sort.Strings(contexts)
	seen := make(map[string]bool)
	records := make([]map[string]any, 0)
	scanned := 0
	for _, projectID := range contexts {
		values := make(url.Values, len(baseValues)+2)
		for name, items := range baseValues {
			values[name] = append([]string(nil), items...)
		}
		values.Del("projectId")
		accountID := query.ViewerAccountID
		if projectID != "" {
			values.Set("projectId", projectID)
			accountID = projectID
		}
		values.Set("accountId", accountID)
		pageRecords, err := b.fetchAllAuditLogsForViewer(ctx, incoming, values, query.ViewerAccountID)
		if err != nil {
			return nil, err // role/session loss is fail-closed, never partial data
		}
		scanned += len(pageRecords)
		if scanned > auditMaximumScanRows {
			return nil, &auditHTTPError{Status: http.StatusUnprocessableEntity, Code: "result_set_too_large", Message: "Narrow the audit log time range or environment before continuing"}
		}
		for _, record := range pageRecords {
			id := auditString(record, "id")
			if !keyAuditIDPattern.MatchString(id) {
				return nil, &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_audit_response", Message: "Audit log service returned an invalid event identifier"}
			}
			if !seen[id] {
				seen[id] = true
				records = append(records, record)
			}
		}
	}
	return records, nil
}

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
	owner, viewer, err := b.fetchKeyAuditAuthorityInProject(ctx, incoming, keyID, "", "")
	if err == nil {
		return owner, viewer, nil // Keep the existing personal/admin visibility fast path.
	}
	var upstreamErr *auditHTTPError
	if !errors.As(err, &upstreamErr) || upstreamErr.Status != http.StatusForbidden || upstreamErr.Code != "key_audit_access_lost" {
		return "", "", err // Never retry an expired session, outage, redirect or invalid response.
	}
	projects, principal, err := b.fetchAuditProjects(ctx, incoming, true)
	if err != nil {
		return "", "", err
	}
	contexts := make([]string, 0, len(projects))
	for id := range projects {
		contexts = append(contexts, id)
	}
	sort.Strings(contexts)
	for _, projectID := range contexts {
		// The shared Engine enumeration only selects candidate scopes. The
		// scoped credential GET rechecks live membership/object/schema access.
		// Neither a caller project header nor an inferred owner is a grant.
		owner, viewer, err = b.fetchKeyAuditAuthorityInProject(ctx, incoming, keyID, projectID, principal)
		if err == nil {
			return owner, viewer, nil
		}
		if !errors.As(err, &upstreamErr) || upstreamErr.Status != http.StatusForbidden || upstreamErr.Code != "key_audit_access_lost" {
			return "", "", err
		}
	}
	return "", "", &auditHTTPError{Status: http.StatusForbidden, Code: "key_audit_access_lost", Message: "The API key is no longer available under your current permissions"}
}

func (b *broker) fetchKeyAuditAuthorityInProject(ctx context.Context, incoming *http.Request, keyID, projectID, principal string) (string, string, error) {
	target := *b.upstreamURL
	client := &http.Client{Timeout: 20 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error {
		return errors.New("API key authority redirects are not allowed")
	}}
	for index, kind := range []string{"apiKey", "apiKeyRestricted"} {
		target.Path, target.RawPath, target.RawQuery, target.Fragment = "/v2-beta/"+strings.ToLower(kind)+"/"+keyID, "", "", ""
		if projectID != "" {
			target.RawQuery = url.Values{"projectId": {projectID}}.Encode()
		}
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
		if projectID != "" && (owner != projectID || viewer != principal || response.Header.Get("X-API-ACCOUNT-ID") != projectID) {
			return "", "", &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_key_authority", Message: "API key environment and current user could not be verified"}
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
