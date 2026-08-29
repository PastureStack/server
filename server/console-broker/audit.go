package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

const (
	auditQueryPath         = "/v2-beta/pasturestack/audit-logs"
	auditExportPath        = "/v2-beta/pasturestack/audit-logs/export"
	auditDefaultRange      = 24 * time.Hour
	auditMaximumRange      = 366 * 24 * time.Hour
	auditMaximumScanRows   = 20000
	auditMaximumPageRows   = 250
	auditMaximumExportRows = 10000
	auditUpstreamPageSize  = 1000
)

type auditQuery struct {
	From                time.Time
	To                  time.Time
	EnvironmentID       string
	UserID              string
	EventType           string
	EventTypeOperator   string
	Description         string
	DescriptionOperator string
	ResourceType        string
	ResourceID          string
	ClientIP            string
	AuthType            string
	Channel             string
	SortBy              string
	SortOrder           string
	Limit               int
	Offset              int
}

type auditResult struct {
	Records     []map[string]any
	Total       int
	Suggestions auditSuggestions
}

type auditSuggestions struct {
	ClientIPs     []string               `json:"clientIps"`
	EventTypes    []string               `json:"eventTypes"`
	ResourceTypes []string               `json:"resourceTypes"`
	Actors        []auditNamedSuggestion `json:"actors"`
}

type auditNamedSuggestion struct {
	ID    string `json:"id"`
	Label string `json:"label"`
}

type auditCollection struct {
	Type         string            `json:"type"`
	ResourceType string            `json:"resourceType"`
	Data         []map[string]any  `json:"data"`
	Filters      map[string]any    `json:"filters"`
	Links        map[string]string `json:"links"`
	Pagination   map[string]any    `json:"pagination"`
}

type auditUpstreamCollection struct {
	Data       []map[string]any `json:"data"`
	Pagination map[string]any   `json:"pagination"`
}

type auditHTTPError struct {
	Status  int
	Code    string
	Message string
}

func (e *auditHTTPError) Error() string {
	return e.Message
}

func (b *broker) serveAudit(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writer.Header().Set("Allow", "GET")
		writeJSONError(writer, http.StatusMethodNotAllowed, "method_not_allowed", "Method not allowed")
		return
	}

	query, err := parseAuditQuery(request.URL.Query(), time.Now().UTC())
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}

	result, err := b.runAuditQuery(request.Context(), request, query)
	if err != nil {
		writeAuditFailure(writer, err)
		return
	}

	if request.URL.Path == auditExportPath {
		if err := writeAuditExport(writer, request, query, result); err != nil {
			b.logger.Printf("audit export failed: %s", safeLogValue(err))
			writeAuditFailure(writer, err)
		}
		return
	}

	writeAuditCollection(writer, request, query, result)
}

func parseAuditQuery(values url.Values, now time.Time) (auditQuery, error) {
	query := auditQuery{
		SortBy:    firstNonEmpty(values.Get("sort"), "created"),
		SortOrder: strings.ToLower(firstNonEmpty(values.Get("order"), "desc")),
		Limit:     100,
	}

	allowedSorts := map[string]bool{
		"id": true, "created": true, "eventType": true, "description": true,
		"accountId": true, "resourceType": true, "authenticatedAsIdentityId": true,
		"actorDisplayName": true, "interactionChannel": true, "clientIp": true,
	}
	if !allowedSorts[query.SortBy] {
		return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_sort", Message: "Unsupported audit log sort field"}
	}
	if query.SortOrder != "asc" && query.SortOrder != "desc" {
		return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_sort_order", Message: "Audit log sort order must be asc or desc"}
	}

	if raw := values.Get("limit"); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed < 1 || parsed > auditMaximumExportRows {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_limit", Message: "Audit log limit is outside the supported range"}
		}
		query.Limit = parsed
	}
	if query.Limit > auditMaximumPageRows {
		query.Limit = auditMaximumPageRows
	}
	if raw := values.Get("offset"); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed < 0 || parsed >= auditMaximumScanRows {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_offset", Message: "Audit log offset is outside the supported range"}
		}
		query.Offset = parsed
	}

	fromValue := firstNonEmpty(values.Get("created_gte"), values.Get("createdFrom"))
	toValue := firstNonEmpty(values.Get("created_lte"), values.Get("createdTo"))
	if fromValue == "" && toValue == "" {
		query.To = now
		query.From = now.Add(-auditDefaultRange)
	} else {
		if fromValue == "" || toValue == "" {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "incomplete_time_range", Message: "Both audit log time boundaries are required"}
		}
		var err error
		query.From, err = time.Parse(time.RFC3339Nano, fromValue)
		if err != nil {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_time_range", Message: "Audit log start time must include a timezone"}
		}
		query.To, err = time.Parse(time.RFC3339Nano, toValue)
		if err != nil {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_time_range", Message: "Audit log end time must include a timezone"}
		}
		query.From = query.From.UTC()
		query.To = query.To.UTC()
	}
	if !query.From.Before(query.To) {
		return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_time_range", Message: "Audit log start time must be earlier than the end time"}
	}
	if query.To.Sub(query.From) > auditMaximumRange {
		return auditQuery{}, &auditHTTPError{Status: http.StatusUnprocessableEntity, Code: "time_range_too_large", Message: "Audit log time range must not exceed 366 days"}
	}

	query.EnvironmentID = cleanAuditValue(values.Get("accountId"), 160)
	query.UserID = cleanAuditValue(values.Get("authenticatedAsAccountId"), 160)
	query.ResourceType = cleanAuditValue(values.Get("resourceType"), 160)
	query.ResourceID = cleanAuditValue(values.Get("resourceId"), 512)
	query.ClientIP = cleanAuditValue(values.Get("clientIp"), 128)
	query.AuthType = cleanAuditValue(values.Get("authType"), 128)
	query.Channel = strings.ToLower(cleanAuditValue(values.Get("interactionChannel"), 64))
	query.EventType, query.EventTypeOperator = parseTextAuditFilter(values, "eventType")
	query.Description, query.DescriptionOperator = parseTextAuditFilter(values, "description")

	if query.Channel != "" {
		if !validAuditChannel(query.Channel) {
			return auditQuery{}, &auditHTTPError{Status: http.StatusBadRequest, Code: "invalid_channel", Message: "Unsupported audit interaction channel"}
		}
	}

	return query, nil
}

func parseTextAuditFilter(values url.Values, field string) (string, string) {
	operators := []struct {
		Suffix   string
		Operator string
	}{
		{"", "exact"}, {"_like", "contains"}, {"_prefix", "startsWith"},
		{"_ne", "notEqual"}, {"_notlike", "notContains"},
	}
	for _, candidate := range operators {
		if value := values.Get(field + candidate.Suffix); value != "" {
			value = cleanAuditValue(value, 512)
			if candidate.Operator == "contains" || candidate.Operator == "notContains" {
				value = strings.Trim(value, "%")
			}
			return value, candidate.Operator
		}
	}
	return "", "contains"
}

func cleanAuditValue(value string, maximum int) string {
	value = strings.TrimSpace(value)
	runes := []rune(value)
	if len(runes) > maximum {
		return string(runes[:maximum])
	}
	return value
}

func (b *broker) runAuditQuery(ctx context.Context, incoming *http.Request, query auditQuery) (auditResult, error) {
	projects, err := b.fetchAuditCollection(ctx, incoming, "/v2-beta/projects", url.Values{
		"all": {"true"}, "limit": {"1000"},
	})
	if err != nil {
		return auditResult{}, err
	}

	allowedProjects := make(map[string]string)
	for _, project := range projects {
		if !strings.EqualFold(auditString(project, "type"), "project") {
			continue
		}
		id := auditString(project, "id")
		if id == "" {
			continue
		}
		allowedProjects[id] = firstNonEmpty(auditString(project, "displayName"), auditString(project, "name"))
	}
	if query.EnvironmentID != "" {
		if _, allowed := allowedProjects[query.EnvironmentID]; !allowed {
			return auditResult{}, &auditHTTPError{Status: http.StatusForbidden, Code: "environment_denied", Message: "The requested environment is not available to this user"}
		}
	}

	accounts, accountErr := b.fetchAuditCollection(ctx, incoming, "/v2-beta/accounts", url.Values{
		"limit": {"1000"}, "kind_ne": {"service", "agent"},
	})
	if accountErr != nil {
		var upstreamErr *auditHTTPError
		if !errors.As(accountErr, &upstreamErr) || (upstreamErr.Status != http.StatusForbidden && upstreamErr.Status != http.StatusNotFound) {
			return auditResult{}, accountErr
		}
		accounts = nil
	}
	accountNames := make(map[string]string)
	for _, account := range accounts {
		id := auditString(account, "id")
		if id == "" {
			continue
		}
		accountNames[id] = firstNonEmpty(auditString(account, "name"), auditString(account, "username"))
	}

	upstreamValues := url.Values{
		"created_gte": {query.From.Format(time.RFC3339Nano)},
		"limit":       {strconv.Itoa(auditUpstreamPageSize)},
		"sort":        {"id"},
		"order":       {"desc"},
	}
	if query.EnvironmentID != "" {
		upstreamValues.Set("accountId", query.EnvironmentID)
	}
	records, err := b.fetchAllAuditLogs(ctx, incoming, upstreamValues)
	if err != nil {
		return auditResult{}, err
	}

	scoped := make([]map[string]any, 0, len(records))
	for _, record := range records {
		projectID := auditString(record, "accountId")
		if _, allowed := allowedProjects[projectID]; !allowed {
			continue
		}
		created, ok := auditTimestamp(record)
		if !ok || created.Before(query.From) || !created.Before(query.To) {
			continue
		}
		if query.EnvironmentID != "" && projectID != query.EnvironmentID {
			continue
		}

		copyRecord := cloneAuditRecord(record)
		copyRecord["environmentDisplayName"] = allowedProjects[projectID]
		actorID := auditString(record, "authenticatedAsAccountId")
		copyRecord["actorDisplayName"] = firstNonEmpty(
			accountNames[actorID],
			auditString(record, "authenticatedAsAccountName"),
			auditString(record, "authenticatedAsIdentityName"),
			auditString(record, "actorDisplayName"),
		)
		copyRecord["interactionChannel"] = auditInteractionChannel(record)
		scoped = append(scoped, copyRecord)
	}

	suggestions := collectAuditSuggestions(scoped)
	filtered := scoped[:0]
	for _, record := range scoped {
		if auditRecordMatches(record, query) {
			filtered = append(filtered, record)
		}
	}

	sort.SliceStable(filtered, func(left, right int) bool {
		comparison := compareAuditRecords(filtered[left], filtered[right], query.SortBy)
		if comparison == 0 {
			comparison = naturalCompare(auditString(filtered[left], "id"), auditString(filtered[right], "id"))
		}
		if query.SortOrder == "desc" {
			return comparison > 0
		}
		return comparison < 0
	})

	return auditResult{Records: filtered, Total: len(filtered), Suggestions: suggestions}, nil
}

func (b *broker) fetchAllAuditLogs(ctx context.Context, incoming *http.Request, values url.Values) ([]map[string]any, error) {
	requestPath := "/v2-beta/auditlogs"
	records := make([]map[string]any, 0, auditUpstreamPageSize)
	for page := 0; page < 100; page++ {
		collection, err := b.fetchAuditPage(ctx, incoming, requestPath, values)
		if err != nil {
			return nil, err
		}
		if len(records)+len(collection.Data) > auditMaximumScanRows {
			return nil, &auditHTTPError{Status: http.StatusUnprocessableEntity, Code: "result_set_too_large", Message: "Narrow the audit log time range or environment before continuing"}
		}
		records = append(records, collection.Data...)
		next := auditMapString(collection.Pagination, "next")
		if next == "" {
			return records, nil
		}
		parsed, err := url.Parse(next)
		if err != nil || parsed.Path != "/v2-beta/auditlogs" {
			return nil, &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_upstream_pagination", Message: "Audit log pagination was rejected"}
		}
		requestPath = parsed.Path
		values = parsed.Query()
	}
	return nil, &auditHTTPError{Status: http.StatusUnprocessableEntity, Code: "result_set_too_large", Message: "Narrow the audit log time range or environment before continuing"}
}

func (b *broker) fetchAuditCollection(ctx context.Context, incoming *http.Request, path string, values url.Values) ([]map[string]any, error) {
	collection, err := b.fetchAuditPage(ctx, incoming, path, values)
	if err != nil {
		return nil, err
	}
	return collection.Data, nil
}

func (b *broker) fetchAuditPage(ctx context.Context, incoming *http.Request, path string, values url.Values) (auditUpstreamCollection, error) {
	target := *b.upstreamURL
	target.Path = path
	target.RawPath = ""
	target.RawQuery = values.Encode()
	target.Fragment = ""

	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		return auditUpstreamCollection{}, err
	}
	copyAuditAuthHeaders(request.Header, incoming.Header)
	request.Header.Set("Accept", "application/json")

	client := &http.Client{Timeout: 20 * time.Second}
	response, err := client.Do(request)
	if err != nil {
		return auditUpstreamCollection{}, &auditHTTPError{Status: http.StatusBadGateway, Code: "audit_upstream_unavailable", Message: "Audit log service is not available"}
	}
	defer response.Body.Close()

	if response.StatusCode < 200 || response.StatusCode >= 300 {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 64*1024))
		status := response.StatusCode
		if status != http.StatusUnauthorized && status != http.StatusForbidden && status != http.StatusNotFound {
			status = http.StatusBadGateway
		}
		return auditUpstreamCollection{}, &auditHTTPError{Status: status, Code: "audit_upstream_denied", Message: "Audit log data is not available to this user"}
	}

	decoder := json.NewDecoder(io.LimitReader(response.Body, 32*1024*1024))
	decoder.UseNumber()
	var collection auditUpstreamCollection
	if err := decoder.Decode(&collection); err != nil {
		return auditUpstreamCollection{}, &auditHTTPError{Status: http.StatusBadGateway, Code: "invalid_audit_response", Message: "Audit log service returned an invalid response"}
	}
	return collection, nil
}

func copyAuditAuthHeaders(target, source http.Header) {
	for _, name := range []string{"Authorization", "Cookie", "X-Api-Auth-Header", "X-Api-No-Challenge", "X-Forwarded-User"} {
		for _, value := range source.Values(name) {
			target.Add(name, value)
		}
	}
}

func auditRecordMatches(record map[string]any, query auditQuery) bool {
	if query.UserID != "" && auditString(record, "authenticatedAsAccountId") != query.UserID {
		return false
	}
	if query.ResourceType != "" && auditString(record, "resourceType") != query.ResourceType {
		return false
	}
	if query.ResourceID != "" && auditString(record, "resourceId") != query.ResourceID {
		return false
	}
	if query.ClientIP != "" && !strings.EqualFold(auditString(record, "clientIp"), query.ClientIP) {
		return false
	}
	if query.AuthType != "" && !strings.EqualFold(auditString(record, "authType"), query.AuthType) {
		return false
	}
	if query.Channel != "" && auditString(record, "interactionChannel") != query.Channel {
		return false
	}
	if !matchAuditText(auditString(record, "eventType"), query.EventType, query.EventTypeOperator) {
		return false
	}
	return matchAuditText(auditString(record, "description"), query.Description, query.DescriptionOperator)
}

func matchAuditText(actual, expected, operator string) bool {
	if expected == "" {
		return true
	}
	actualFolded := strings.ToLower(actual)
	expectedFolded := strings.ToLower(expected)
	switch operator {
	case "exact":
		return actualFolded == expectedFolded
	case "startsWith":
		return strings.HasPrefix(actualFolded, expectedFolded)
	case "notEqual":
		return actualFolded != expectedFolded
	case "notContains":
		return !strings.Contains(actualFolded, expectedFolded)
	default:
		return strings.Contains(actualFolded, expectedFolded)
	}
}

func auditInteractionChannel(record map[string]any) string {
	if channel := strings.ToLower(auditString(record, "interactionChannel")); validAuditChannel(channel) {
		return channel
	}
	authType := strings.ToLower(auditString(record, "authType"))
	switch {
	case authType == "tokenauth", strings.Contains(authType, "uisession"), strings.Contains(authType, "session"):
		return "web_ui"
	case authType == "basicauth", authType == "tokenaccount", strings.Contains(authType, "apikey"), strings.Contains(authType, "header"):
		return "public_api"
	case strings.Contains(authType, "host"), strings.Contains(authType, "registration"), strings.Contains(authType, "agent"):
		return "automation"
	case authType == "", authType == "none", authType == "adminauth":
		return "system_internal"
	default:
		return "unknown"
	}
}

func validAuditChannel(channel string) bool {
	switch channel {
	case "web_ui", "public_api", "automation", "system_internal", "unknown":
		return true
	default:
		return false
	}
}

func collectAuditSuggestions(records []map[string]any) auditSuggestions {
	ipSet := map[string]bool{}
	eventSet := map[string]bool{}
	resourceSet := map[string]bool{}
	actorSet := map[string]string{}
	for _, record := range records {
		if value := auditString(record, "clientIp"); value != "" {
			ipSet[value] = true
		}
		if value := auditString(record, "eventType"); value != "" {
			eventSet[value] = true
		}
		if value := auditString(record, "resourceType"); value != "" {
			resourceSet[value] = true
		}
		actorID := auditString(record, "authenticatedAsAccountId")
		actorLabel := auditString(record, "actorDisplayName")
		if actorID != "" && actorLabel != "" {
			actorSet[actorID] = actorLabel
		}
	}
	return auditSuggestions{
		ClientIPs: naturalSetValues(ipSet, 100), EventTypes: naturalSetValues(eventSet, 100), ResourceTypes: naturalSetValues(resourceSet, 100),
		Actors: naturalNamedSuggestions(actorSet, 250),
	}
}

func naturalNamedSuggestions(values map[string]string, maximum int) []auditNamedSuggestion {
	result := make([]auditNamedSuggestion, 0, len(values))
	for id, label := range values {
		result = append(result, auditNamedSuggestion{ID: id, Label: label})
	}
	sort.Slice(result, func(left, right int) bool {
		comparison := naturalCompare(result[left].Label, result[right].Label)
		if comparison == 0 {
			comparison = naturalCompare(result[left].ID, result[right].ID)
		}
		return comparison < 0
	})
	if len(result) > maximum {
		result = result[:maximum]
	}
	return result
}

func naturalSetValues(values map[string]bool, maximum int) []string {
	result := make([]string, 0, len(values))
	for value := range values {
		result = append(result, value)
	}
	sort.Slice(result, func(left, right int) bool { return naturalCompare(result[left], result[right]) < 0 })
	if len(result) > maximum {
		result = result[:maximum]
	}
	return result
}

func compareAuditRecords(left, right map[string]any, field string) int {
	if field == "created" {
		leftTime, leftOK := auditTimestamp(left)
		rightTime, rightOK := auditTimestamp(right)
		if leftOK && rightOK && !leftTime.Equal(rightTime) {
			if leftTime.Before(rightTime) {
				return -1
			}
			return 1
		}
	}
	sortField := field
	switch field {
	case "accountId":
		sortField = "environmentDisplayName"
	case "authenticatedAsIdentityId":
		sortField = "actorDisplayName"
	}
	return naturalCompare(auditString(left, sortField), auditString(right, sortField))
}

func naturalCompare(left, right string) int {
	leftRunes := []rune(strings.ToLower(left))
	rightRunes := []rune(strings.ToLower(right))
	for leftIndex, rightIndex := 0, 0; leftIndex < len(leftRunes) || rightIndex < len(rightRunes); {
		if leftIndex >= len(leftRunes) {
			return -1
		}
		if rightIndex >= len(rightRunes) {
			return 1
		}
		leftDigit := leftRunes[leftIndex] >= '0' && leftRunes[leftIndex] <= '9'
		rightDigit := rightRunes[rightIndex] >= '0' && rightRunes[rightIndex] <= '9'
		if leftDigit && rightDigit {
			leftEnd, rightEnd := leftIndex, rightIndex
			for leftEnd < len(leftRunes) && leftRunes[leftEnd] >= '0' && leftRunes[leftEnd] <= '9' {
				leftEnd++
			}
			for rightEnd < len(rightRunes) && rightRunes[rightEnd] >= '0' && rightRunes[rightEnd] <= '9' {
				rightEnd++
			}
			leftNumber := strings.TrimLeft(string(leftRunes[leftIndex:leftEnd]), "0")
			rightNumber := strings.TrimLeft(string(rightRunes[rightIndex:rightEnd]), "0")
			if leftNumber == "" {
				leftNumber = "0"
			}
			if rightNumber == "" {
				rightNumber = "0"
			}
			if len(leftNumber) != len(rightNumber) {
				if len(leftNumber) < len(rightNumber) {
					return -1
				}
				return 1
			}
			if leftNumber != rightNumber {
				if leftNumber < rightNumber {
					return -1
				}
				return 1
			}
			leftIndex, rightIndex = leftEnd, rightEnd
			continue
		}
		if leftRunes[leftIndex] != rightRunes[rightIndex] {
			if leftRunes[leftIndex] < rightRunes[rightIndex] {
				return -1
			}
			return 1
		}
		leftIndex++
		rightIndex++
	}
	return 0
}

func auditTimestamp(record map[string]any) (time.Time, bool) {
	value := auditString(record, "created")
	parsed, err := time.Parse(time.RFC3339Nano, value)
	return parsed, err == nil
}

func auditString(record map[string]any, key string) string {
	value, ok := record[key]
	if !ok || value == nil {
		return ""
	}
	switch typed := value.(type) {
	case string:
		return typed
	case json.Number:
		return typed.String()
	default:
		return fmt.Sprint(typed)
	}
}

func auditMapString(values map[string]any, key string) string {
	if values == nil {
		return ""
	}
	value, ok := values[key]
	if !ok || value == nil {
		return ""
	}
	return fmt.Sprint(value)
}

func cloneAuditRecord(record map[string]any) map[string]any {
	clone := make(map[string]any, len(record)+3)
	for key, value := range record {
		clone[key] = value
	}
	return clone
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}

func writeAuditCollection(writer http.ResponseWriter, request *http.Request, query auditQuery, result auditResult) {
	start := query.Offset
	if start > result.Total {
		start = result.Total
	}
	end := start + query.Limit
	if end > result.Total {
		end = result.Total
	}
	page := result.Records[start:end]

	self := *request.URL
	self.Scheme, self.Host = "", ""
	pagination := map[string]any{"limit": query.Limit, "total": result.Total}
	if end < result.Total {
		next := self
		values := next.Query()
		values.Set("offset", strconv.Itoa(end))
		next.RawQuery = values.Encode()
		pagination["next"] = next.String()
	}
	if start > 0 {
		previous := self
		values := previous.Query()
		previousOffset := start - query.Limit
		if previousOffset < 0 {
			previousOffset = 0
		}
		values.Set("offset", strconv.Itoa(previousOffset))
		previous.RawQuery = values.Encode()
		pagination["previous"] = previous.String()
	}

	payload := auditCollection{
		Type: "collection", ResourceType: "auditLog", Data: page,
		Filters: map[string]any{"suggestions": result.Suggestions},
		Links:   map[string]string{"self": self.String()}, Pagination: pagination,
	}
	writer.Header().Set("Content-Type", "application/json; charset=utf-8")
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	_ = json.NewEncoder(writer).Encode(payload)
}

func writeAuditFailure(writer http.ResponseWriter, err error) {
	var typed *auditHTTPError
	if errors.As(err, &typed) {
		writeJSONError(writer, typed.Status, typed.Code, typed.Message)
		return
	}
	writeJSONError(writer, http.StatusInternalServerError, "audit_query_failed", "Unable to query audit logs")
}
