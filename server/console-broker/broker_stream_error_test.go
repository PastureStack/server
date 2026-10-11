package main

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestSessionCreationPreservesOnlyTrustedStreamFailureContract(t *testing.T) {
	for _, testCase := range []struct {
		name           string
		status         int
		upstreamHeader string
		upstreamCode   string
		wantStatus     int
		wantCode       string
	}{
		{"verified backend capability block", http.StatusServiceUnavailable, streamErrorHeader, backendAuditUnavailable, http.StatusServiceUnavailable, backendAuditUnavailable},
		{"durable failure receipt unavailable", http.StatusServiceUnavailable, streamErrorHeader, streamAuditUnavailable, http.StatusServiceUnavailable, streamAuditUnavailable},
		{"client header cannot upgrade generic 503", http.StatusServiceUnavailable, streamErrorHeader, "", http.StatusBadGateway, "upstream_unavailable"},
		{"matching code without 503 is not the contract", http.StatusForbidden, streamErrorHeader, backendAuditUnavailable, http.StatusBadGateway, "upstream_unavailable"},
		{"unknown upstream code is not reflected", http.StatusServiceUnavailable, streamErrorHeader, "private-upstream-error", http.StatusBadGateway, "upstream_unavailable"},
		{"signed route denial remains 403", http.StatusForbidden, routeErrorHeader, streamRouteDenied, http.StatusForbidden, streamRouteDenied},
		{"client header cannot upgrade generic 403", http.StatusForbidden, routeErrorHeader, "", http.StatusBadGateway, "upstream_unavailable"},
		{"unknown route code is not reflected", http.StatusForbidden, routeErrorHeader, "private-upstream-error", http.StatusBadGateway, "upstream_unavailable"},
		{"route code without 403 is not the contract", http.StatusServiceUnavailable, routeErrorHeader, streamRouteDenied, http.StatusBadGateway, "upstream_unavailable"},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			const ticket = "signed-ticket-never-log-this-123456789"
			const backendTicket = "backend-ticket-never-reflect-this"
			const secret = "3023456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
			var attempts atomic.Int32
			var forwardedClientSignal atomic.Bool
			upstream := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
				attempts.Add(1)
				if request.Header.Get(streamErrorHeader) != "" || request.Header.Get(routeErrorHeader) != "" || request.Header.Get("Authorization") != "" || request.Header.Get("Cookie") != "" {
					forwardedClientSignal.Store(true)
				}
				if request.URL.Query().Get("token") != ticket {
					t.Error("the actual upstream handshake lost its ticket")
				}
				writer.Header().Set(testCase.upstreamHeader, testCase.upstreamCode)
				writer.WriteHeader(testCase.status)
				_, _ = io.WriteString(writer, ticket+" "+backendTicket)
			}))
			defer upstream.Close()
			var logs bytes.Buffer
			instance, err := newBroker(brokerConfig{
				UpstreamURL: upstream.URL, SessionDialURL: upstream.URL,
				MaxSessions: 8, CleanupInterval: time.Hour,
				SessionDialRetryWait: time.Millisecond,
			}, log.New(&logs, "", 0))
			if err != nil {
				t.Fatal(err)
			}
			defer instance.close()
			server := httptest.NewServer(instance)
			defer server.Close()
			body, err := json.Marshal(createSessionRequest{
				Secret: secret, Kind: "logs",
				Target: "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/exec?private=" + backendTicket,
				Token:  ticket,
			})
			if err != nil {
				t.Fatal(err)
			}
			request, err := http.NewRequest(http.MethodPost, server.URL+sessionPathPrefix+"psw_abcdefghijklmnopqrstuv03", bytes.NewReader(body))
			if err != nil {
				t.Fatal(err)
			}
			request.Header.Set("Content-Type", "application/json")
			request.Header.Set(streamErrorHeader, backendAuditUnavailable)
			request.Header.Set(routeErrorHeader, streamRouteDenied)
			request.Header.Set("Authorization", "Bearer "+backendTicket)
			request.Header.Set("Cookie", "session="+backendTicket)
			response, err := server.Client().Do(request)
			if err != nil {
				t.Fatal(err)
			}
			defer response.Body.Close()
			responseBody, err := io.ReadAll(response.Body)
			if err != nil {
				t.Fatal(err)
			}
			var frame errorFrame
			if err := json.Unmarshal(responseBody, &frame); err != nil {
				t.Fatal(err)
			}
			if response.StatusCode != testCase.wantStatus || frame.Code != testCase.wantCode {
				t.Fatalf("unexpected handshake response: status=%d code=%s", response.StatusCode, frame.Code)
			}
			wantHeader := ""
			if testCase.wantStatus == http.StatusServiceUnavailable {
				wantHeader = testCase.wantCode
			}
			if response.Header.Get(streamErrorHeader) != wantHeader || response.Header.Get("Cache-Control") != "no-store" {
				t.Fatal("handshake response lost its fixed safe header/cache contract")
			}
			wantRouteHeader := ""
			if testCase.wantStatus == http.StatusForbidden {
				wantRouteHeader = streamRouteDenied
			}
			if response.Header.Get(routeErrorHeader) != wantRouteHeader {
				t.Fatal("route denial response lost its fixed safe header contract")
			}
			if attempts.Load() != 1 || instance.activeSessionCount() != 0 || forwardedClientSignal.Load() {
				t.Fatal("a blocked handshake retried, created a session, or trusted browser metadata")
			}
			for _, sensitive := range []string{ticket, backendTicket, secret, "private-upstream-error"} {
				if strings.Contains(string(responseBody), sensitive) || strings.Contains(logs.String(), sensitive) {
					t.Fatal("handshake response or logger retained private upstream material")
				}
			}
		})
	}
}
