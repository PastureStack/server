package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"time"
)

const aiAuditQueryPath = "/v2-beta/pasturestack/ai-audit-queries"

var aiAuditToken = regexp.MustCompile("^[A-Za-z0-9][A-Za-z0-9_.:-]{0,159}$")

type aiAuditReadContext struct{}

func isAIAuditRead(ctx context.Context) bool {
	return ctx.Value(aiAuditReadContext{}) == true
}

// Fixed read workflow. Locators remain subject to the original audit owner;
// neither tool references nor caller-selected identity headers grant access.
type aiAuditInput struct {
	KeyID         string `json:"keyId,omitempty"`
	EnvironmentID string `json:"environmentId,omitempty"`
	From          string `json:"from,omitempty"`
	To            string `json:"to,omitempty"`
	LastMinutes   *int   `json:"lastMinutes,omitempty"`
	Decision      string `json:"decision,omitempty"`
	Outcome       string `json:"outcome,omitempty"`
	Operation     string `json:"operation,omitempty"`
	TargetType    string `json:"targetType,omitempty"`
	RequestID     string `json:"requestId,omitempty"`
	HTTPStatus    *int   `json:"httpStatus,omitempty"`
	Limit         *int   `json:"limit,omitempty"`
	Offset        *int   `json:"offset,omitempty"`
	EventID       string `json:"eventId,omitempty"`
}

func aiAuditInvalid() error {
	return &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_ai_audit_query", Message: "Use typed audit filters and a bounded time range"}
}

func (input aiAuditInput) query(now time.Time) (auditQuery, error) {
	values := url.Values{"sort": {"created"}, "order": {"desc"}, "limit": {"50"}}
	for name, value := range map[string]string{
		"keyId": input.KeyID, "accountId": input.EnvironmentID, "eventId": input.EventID,
		"decision": input.Decision, "outcome": input.Outcome, "operation": input.Operation,
		"targetType": input.TargetType, "requestId": input.RequestID,
	} {
		if value != "" {
			if !aiAuditToken.MatchString(value) {
				return auditQuery{}, aiAuditInvalid()
			}
			values.Set(name, value)
		}
	}
	if input.Decision != "" && input.Decision != "ALLOW" && input.Decision != "DENY" && input.Decision != "NOT_EVALUATED" {
		return auditQuery{}, aiAuditInvalid()
	}
	if input.LastMinutes != nil {
		if *input.LastMinutes < 1 || *input.LastMinutes > 366*24*60 || input.From != "" || input.To != "" {
			return auditQuery{}, aiAuditInvalid()
		}
		input.From = now.Add(-time.Duration(*input.LastMinutes) * time.Minute).Format(time.RFC3339Nano)
		input.To = now.Format(time.RFC3339Nano)
	}
	if input.From != "" || input.To != "" {
		values.Set("timeScope", "range")
		values.Set("created_gte", input.From)
		values.Set("created_lte", input.To)
	}
	if input.Limit != nil {
		if *input.Limit < 1 || *input.Limit > 50 {
			return auditQuery{}, aiAuditInvalid()
		}
		values.Set("limit", strconv.Itoa(*input.Limit))
	}
	if input.Offset != nil {
		values.Set("offset", strconv.Itoa(*input.Offset))
	}
	if input.HTTPStatus != nil {
		if *input.HTTPStatus < 100 || *input.HTTPStatus > 599 {
			return auditQuery{}, aiAuditInvalid()
		}
		values.Set("httpStatus", strconv.Itoa(*input.HTTPStatus))
	}
	return parseAuditQuery(values, now)
}

func (b *broker) serveAIAudit(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writer.Header().Set("Allow", "POST")
		writeJSONError(writer, http.StatusMethodNotAllowed, "method_not_allowed", "Method not allowed")
		return
	}
	// Presence restricts this first adapter to native Cookie transport. Only
	// the existing Engine/native owner below authenticates that cookie.
	cookie := request.Header.Get("Cookie")
	if auditOwner(request.Context()) == nil && (cookie == "" || len(cookie) > 32768 || request.Header.Get("Authorization") != "") {
		writeJSONError(writer, http.StatusForbidden, "ai_audit_cookie_required", "This audit workflow requires the current native browser session")
		return
	}
	var input *aiAuditInput
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, 8192))
	decoder.DisallowUnknownFields()
	if request.URL.RawQuery != "" || decoder.Decode(&input) != nil || input == nil || decoder.Decode(&struct{}{}) != io.EOF {
		writeAuditFailure(writer, aiAuditInvalid())
		return
	}
	query, err := input.query(time.Now().UTC())
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}
	// No caller actor/project/forwarded-identity header is forwarded as a grant.
	native := request.Clone(context.WithValue(request.Context(), aiAuditReadContext{}, true))
	native.Header = make(http.Header)
	native.Header.Set("Cookie", cookie)
	if auditOwner(request.Context()) != nil && request.Header.Get("Authorization") != "" {
		native.Header.Set("Authorization", request.Header.Get("Authorization"))
	}
	if input.KeyID != "" {
		owner, viewer, err := b.fetchKeyAuditAuthority(native.Context(), native, input.KeyID)
		if err != nil {
			writeAuditFailure(writer, err)
			return
		}
		query.KeyID, query.KeyOwnerAccountID, query.ViewerAccountID = input.KeyID, owner, viewer
	}
	result, err := b.runAuditQuery(native.Context(), native, query)
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}
	if input.EventID != "" {
		found := make([]map[string]any, 0, 1)
		for _, row := range result.Records {
			if auditString(row, "id") == input.EventID {
				found = append(found, row)
			}
		}
		if len(found) != 1 {
			writeJSONError(writer, http.StatusNotFound, "ai_audit_event_unavailable", "The event is unavailable under this query and current permissions")
			return
		}
		result.Records, result.Total, query.Offset = found, 1, 0
	}
	start := query.Offset
	if start > result.Total {
		start = result.Total
	}
	end := start + query.Limit
	if end > result.Total {
		end = result.Total
	}
	rows := make([]map[string]any, 0, end-start)
	for _, row := range result.Records[start:end] {
		projected := safeAIAuditRecord(row, input.KeyID)
		if !aiAuditToken.MatchString(auditString(projected, "id")) {
			writeJSONError(writer, http.StatusBadGateway, "invalid_audit_response", "The audit owner returned an invalid event identity")
			return
		}
		rows = append(rows, projected)
	}
	var next any
	if end < result.Total {
		next = end
	}
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	_ = json.NewEncoder(writer).Encode(map[string]any{
		"resourceType": "auditLog", "data": rows, "total": result.Total, "nextOffset": next,
		"range":         map[string]string{"from": query.From.Format(time.RFC3339Nano), "to": query.To.Format(time.RFC3339Nano)},
		"payloadPolicy": "HUMAN_ONLY_NATIVE_AUDIT_UI",
	})
}

func safeAIAuditRecord(record map[string]any, keyID string) map[string]any {
	metadata := safeKeyAuditRecord(record, keyID)
	result := map[string]any{"type": "auditLog", "payloadsIncluded": false}
	for _, field := range []string{
		"id", "accountId", "authenticatedAsAccountId", "keyId", "eventType", "resourceType", "resourceId",
		"authType", "decision", "outcome", "responseCode", "requestId", "targetType", "targetId",
		"operation", "phase", "processId", "processName", "failureCode",
	} {
		if value := auditString(metadata, field); aiAuditToken.MatchString(value) {
			result[field] = value
		}
	}
	if created, valid := auditTimestamp(record); valid {
		result["created"] = created.UTC().Format(time.RFC3339Nano)
	}
	for _, field := range []string{"httpStatus", "policyRevision"} {
		value, err := strconv.ParseInt(auditString(metadata, field), 10, 64)
		if err == nil && value >= 0 && value <= 9007199254740991 {
			result[field] = value
		}
	}
	if value, ok := metadata["preview"].(bool); ok {
		result["preview"] = value
	}
	for _, field := range []string{"request", "response"} {
		state := "not_projected"
		if value, present := record[field+"Object"]; present && value != nil {
			state = "present"
		}
		result[field+"PayloadPresence"] = state
	}
	if value := auditInteractionChannel(record); validAuditChannel(value) {
		result["interactionChannel"] = value
	}
	return result
}
