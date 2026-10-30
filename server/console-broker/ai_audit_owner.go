package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

// This envelope is accepted only by the fixed local CLI, never by an HTTP route.
// Credentials arrive through private stdin, not argv, environment or logs.
type aiAuditOwnerInput struct {
	Query          *aiAuditInput `json:"query"`
	ActorID        string        `json:"actorId"`
	Cookie         string        `json:"cookie,omitempty"`
	Authorization  string        `json:"authorization,omitempty"`
	CredentialID   string        `json:"credentialId,omitempty"`
	CredentialKind string        `json:"credentialKind,omitempty"`
	Revision       int64         `json:"revision,omitempty"`
}

type aiAuditOwnerContext struct{}
type aiAuditOwnerState struct {
	input aiAuditOwnerInput
}

func auditOwner(ctx context.Context) *aiAuditOwnerState {
	state, _ := ctx.Value(aiAuditOwnerContext{}).(*aiAuditOwnerState)
	return state
}

type boundedAuditResponse struct {
	header http.Header
	status int
	body   bytes.Buffer
}

func (w *boundedAuditResponse) Header() http.Header { return w.header }
func (w *boundedAuditResponse) WriteHeader(status int) {
	if w.status == 0 {
		w.status = status
	}
}
func (w *boundedAuditResponse) Write(data []byte) (int, error) {
	if w.status == 0 {
		w.status = 200
	}
	if w.body.Len()+len(data) > 512*1024 {
		return 0, errors.New("audit output bound")
	}
	return w.body.Write(data)
}

func runAIAuditOwnerCLI(stdin io.Reader, stdout io.Writer) int {
	var input *aiAuditOwnerInput
	decoder := json.NewDecoder(io.LimitReader(stdin, 65537))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&input) != nil || input == nil || decoder.Decode(&struct{}{}) != io.EOF ||
		input.Query == nil || !keyAuditIDPattern.MatchString(input.ActorID) ||
		(input.Cookie == "") == (input.Authorization == "") || len(input.Cookie)+len(input.Authorization) > 32768 ||
		input.Authorization != "" && (!strings.HasPrefix(input.Authorization, "Basic ") ||
			input.Revision < 1 || !keyAuditIDPattern.MatchString(input.CredentialID) ||
			input.CredentialKind != "apiKey" && input.CredentialKind != "apiKeyRestricted") {
		return 2 // No private input or diagnostic is printed.
	}
	cfg := brokerConfig{UpstreamURL: consoleUpstreamFromEnvironment(), SessionDialURL: "http://127.0.0.1:8080",
		MaxSessions: 1, ReplayBytes: 65536, ActiveTTL: time.Hour, HistoryTTL: time.Hour, CleanupInterval: time.Hour}
	b, err := newBroker(cfg, log.New(io.Discard, "", 0))
	if err != nil {
		return 2
	}
	defer b.close()
	return executeAIAuditOwner(b, *input, stdout)
}

func executeAIAuditOwner(b *broker, input aiAuditOwnerInput, stdout io.Writer) int {
	ctx, cancel := context.WithTimeout(context.Background(), 40*time.Second)
	defer cancel()
	ctx = context.WithValue(ctx, aiAuditOwnerContext{}, &aiAuditOwnerState{input: input})
	payload, err := json.Marshal(input.Query)
	if err != nil {
		return 2
	}
	request, _ := http.NewRequestWithContext(ctx, "POST", "http://127.0.0.1"+aiAuditQueryPath, bytes.NewReader(payload))
	if input.Cookie != "" {
		request.Header.Set("Cookie", input.Cookie)
	}
	if input.Authorization != "" {
		request.Header.Set("Authorization", input.Authorization)
	}
	response := &boundedAuditResponse{header: make(http.Header)}
	b.serveAIAudit(response, request)
	var body map[string]any
	if json.Unmarshal(response.body.Bytes(), &body) != nil {
		return 2
	}
	if json.NewEncoder(stdout).Encode(map[string]any{"status": response.status, "body": body}) != nil {
		return 2
	}
	return 0
}

// Every source is still the native manager's current role/Key read. This adapter
// has no SQL, service credential or raw-payload fallback.
func (b *broker) fetchAIAuditSource(ctx context.Context, incoming *http.Request, category, resourceID, projectID, keyKind string, values url.Values) (auditUpstreamCollection, error) {
	state := auditOwner(ctx)
	if state == nil {
		return auditUpstreamCollection{}, aiAuditInvalid()
	}
	page := map[string]any{"limit": 1000}
	for native, typed := range map[string]string{"marker": "marker", "projectId": "projectId", "accountId": "accountId", "created_gte": "from", "created_lte": "to"} {
		if value := values.Get(native); value != "" {
			page[typed] = value
		}
	}
	if projectID != "" {
		page["projectId"] = projectID
	}
	if keyKind != "" {
		page["keyKind"] = keyKind
	}
	body := map[string]any{"resourceType": category, "sourcePage": page}
	if resourceID != "" {
		body["resourceId"] = resourceID
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return auditUpstreamCollection{}, aiAuditInvalid()
	}
	target := *b.upstreamURL
	target.Path = "/v2-beta/aiResourceViews"
	target.RawPath = ""
	target.RawQuery = ""
	target.Fragment = ""
	request, err := http.NewRequestWithContext(ctx, "POST", target.String(), bytes.NewReader(payload))
	if err != nil {
		return auditUpstreamCollection{}, aiAuditInvalid()
	}
	request.Header.Set("Content-Type", "application/json")
	if state.input.Cookie != "" {
		request.Header.Set("Cookie", state.input.Cookie)
	}
	if state.input.Authorization != "" {
		request.Header.Set("Authorization", state.input.Authorization)
		request.Header.Set("X-PastureStack-Key-Expected-Revision", strconv.FormatInt(state.input.Revision, 10))
	}
	client := &http.Client{Timeout: 20 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return errors.New("audit source redirect denied") }}
	response, err := client.Do(request)
	if err != nil {
		return auditUpstreamCollection{}, &auditHTTPError{Status: 502, Code: "audit_upstream_unavailable", Message: "Audit source unavailable"}
	}
	defer response.Body.Close()
	if response.StatusCode != 200 && response.StatusCode != 201 {
		status := response.StatusCode
		if status != 401 && status != 403 && status != 404 && status != 422 {
			status = 502
		}
		return auditUpstreamCollection{}, &auditHTTPError{Status: status, Code: "audit_upstream_denied", Message: "Audit source denied"}
	}
	var result struct {
		ResourceType     string           `json:"resourceType"`
		Data             []map[string]any `json:"data"`
		NextMarker       *string          `json:"nextMarker"`
		SourcePageResult bool             `json:"sourcePageResult"`
		Authority        struct {
			ActorID      string `json:"actorId"`
			AccountID    string `json:"accountId"`
			CredentialID string `json:"credentialId"`
			Revision     int64  `json:"credentialRevision"`
			Kind         string `json:"credentialKind"`
		} `json:"nativeAuthority"`
	}
	decoder := json.NewDecoder(io.LimitReader(response.Body, 4*1024*1024+1))
	decoder.UseNumber()
	if decoder.Decode(&result) != nil || decoder.Decode(&struct{}{}) != io.EOF || !result.SourcePageResult || len(result.Data) > 1000 ||
		result.ResourceType != firstNonEmpty(keyKind, category) || result.Authority.ActorID != state.input.ActorID ||
		!keyAuditIDPattern.MatchString(result.Authority.AccountID) ||
		result.Authority.AccountID != firstNonEmpty(projectID, values.Get("projectId"), state.input.ActorID) ||
		state.input.Authorization != "" && (result.Authority.CredentialID != state.input.CredentialID ||
			result.Authority.Revision != state.input.Revision || result.Authority.Kind != state.input.CredentialKind) ||
		state.input.Authorization == "" && (result.Authority.CredentialID != "" || result.Authority.Revision != 0 || result.Authority.Kind != "") {
		return auditUpstreamCollection{}, &auditHTTPError{Status: 502, Code: "invalid_key_authority", Message: "Audit source authority changed"}
	}
	collection := auditUpstreamCollection{Data: result.Data, Pagination: map[string]any{}, viewerAccountID: result.Authority.ActorID}
	if result.NextMarker != nil {
		if len(result.Data) == 0 || !keyAuditIDPattern.MatchString(*result.NextMarker) ||
			*result.NextMarker != auditString(result.Data[len(result.Data)-1], "id") || *result.NextMarker == values.Get("marker") {
			return auditUpstreamCollection{}, &auditHTTPError{Status: 502, Code: "invalid_audit_response", Message: "Audit source pagination rejected"}
		}
		next := url.Values{}
		for name, items := range values {
			next[name] = append([]string(nil), items...)
		}
		next.Set("marker", *result.NextMarker)
		collection.Pagination["next"] = "/v2-beta/auditlogs?" + next.Encode()
	}
	return collection, nil
}

// Public route forwards one fixed typed Engine request. The Engine then invokes
// the private CLI and records the actual whole-query outcome in its durable sink.
func (b *broker) serveAIAuditGateway(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		w.Header().Set("Allow", "POST")
		writeJSONError(w, 405, "method_not_allowed", "Method not allowed")
		return
	}
	if r.URL.RawQuery != "" {
		writeAuditFailure(w, aiAuditInvalid())
		return
	}
	body, err := io.ReadAll(io.LimitReader(r.Body, 8193))
	if err != nil || len(body) > 8192 {
		writeAuditFailure(w, aiAuditInvalid())
		return
	}
	target := *b.upstreamURL
	target.Path = "/v2-beta/aiAuditQueries"
	target.RawPath = ""
	target.RawQuery = ""
	target.Fragment = ""
	request, err := http.NewRequestWithContext(r.Context(), "POST", target.String(), bytes.NewReader(body))
	if err != nil {
		writeJSONError(w, 502, "audit_query_failed", "Audit query unavailable")
		return
	}
	for _, header := range []string{"Cookie", "Authorization", "X-PastureStack-Key-Expected-Revision"} {
		if value := r.Header.Get(header); value != "" {
			request.Header.Set(header, value)
		}
	}
	request.Header.Set("Content-Type", "application/json")
	client := &http.Client{Timeout: 50 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return errors.New("audit gateway redirect denied") }}
	response, err := client.Do(request)
	if err != nil {
		writeJSONError(w, 502, "audit_query_failed", "Audit query unavailable")
		return
	}
	defer response.Body.Close()
	result, err := io.ReadAll(io.LimitReader(response.Body, 512*1024+1))
	if err != nil || len(result) > 512*1024 {
		writeJSONError(w, 502, "audit_query_failed", "Audit query unavailable")
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	for _, header := range []string{"X-PastureStack-Key-Purpose", "X-PastureStack-Key-Revision"} {
		if value := response.Header.Get(header); value != "" {
			w.Header().Set(header, value)
		}
	}
	w.WriteHeader(response.StatusCode)
	_, _ = w.Write(result)
}

func aiAuditCLI() bool {
	if len(os.Args) == 2 && os.Args[1] == "--ai-audit-query" {
		os.Exit(runAIAuditOwnerCLI(os.Stdin, os.Stdout))
		return true
	}
	return false
}
