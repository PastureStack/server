package main

import (
	"encoding/base64"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"net/url"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

type upstreamRecorder struct {
	server   *httptest.Server
	upgrader websocket.Upgrader
	mu       sync.Mutex
	inputs   []string
	origins  []string
	output   chan string
	rejects  int
	attempts int
}

func newUpstreamRecorder(t *testing.T) *upstreamRecorder {
	return newUpstreamRecorderWithOriginCheck(t, false)
}

func newUpstreamRecorderWithOriginCheck(t *testing.T, requireSameOrigin bool) *upstreamRecorder {
	return newUpstreamRecorderWithFailures(t, requireSameOrigin, 0)
}

func newUpstreamRecorderWithFailures(t *testing.T, requireSameOrigin bool, rejects int) *upstreamRecorder {
	t.Helper()
	recorder := &upstreamRecorder{
		output:  make(chan string, 16),
		rejects: rejects,
	}
	recorder.upgrader.CheckOrigin = func(request *http.Request) bool {
		recorder.mu.Lock()
		recorder.origins = append(recorder.origins, request.Header.Get("Origin"))
		recorder.mu.Unlock()
		if !requireSameOrigin {
			return true
		}
		return requestOriginAllowed(request)
	}
	recorder.server = httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/exec" || request.URL.Query().Get("token") != "valid-token" {
			http.NotFound(writer, request)
			return
		}
		recorder.mu.Lock()
		recorder.attempts++
		shouldReject := recorder.rejects > 0
		if shouldReject {
			recorder.rejects--
		}
		recorder.mu.Unlock()
		if shouldReject {
			http.Error(writer, "backend registration pending", http.StatusUnauthorized)
			return
		}
		connection, err := recorder.upgrader.Upgrade(writer, request, nil)
		if err != nil {
			return
		}
		defer connection.Close()
		done := make(chan struct{})
		go func() {
			defer close(done)
			for {
				_, payload, err := connection.ReadMessage()
				if err != nil {
					return
				}
				recorder.mu.Lock()
				recorder.inputs = append(recorder.inputs, string(payload))
				recorder.mu.Unlock()
			}
		}()
		for {
			select {
			case payload := <-recorder.output:
				if err := connection.WriteMessage(websocket.TextMessage, []byte(payload)); err != nil {
					return
				}
			case <-done:
				return
			}
		}
	}))
	return recorder
}

func TestSessionCreationRetriesBackendRegistrationRace(t *testing.T) {
	upstream := newUpstreamRecorderWithFailures(t, true, 2)
	defer upstream.close()
	instance, server := newTestBroker(t, upstream)
	instance.config.SessionDialRetryWait = time.Millisecond

	createSession(
		t,
		server.URL,
		upstream.server.URL,
		"psw_abcdefghijklmnopqrstuv02",
		"2023456789abcdefghijklmnopqrstuvwxyzABCDEFGH",
		"logs",
	)

	upstream.mu.Lock()
	attempts := upstream.attempts
	upstream.mu.Unlock()
	if attempts != 3 {
		t.Fatalf("backend registration race used %d attempts, expected 3", attempts)
	}
}

func TestSessionCreationBackendRetryIsBounded(t *testing.T) {
	upstream := newUpstreamRecorderWithFailures(t, true, 10)
	defer upstream.close()
	instance, server := newTestBroker(t, upstream)
	instance.config.SessionDialRetryWait = time.Millisecond

	requestBody, _ := json.Marshal(createSessionRequest{
		Secret: "3023456789abcdefghijklmnopqrstuvwxyzABCDEFGH",
		Kind:   "logs",
		Target: "ws" + strings.TrimPrefix(server.URL, "http") + "/v1/exec",
		Token:  "valid-token",
	})
	request, _ := http.NewRequest(
		http.MethodPost,
		server.URL+sessionPathPrefix+"psw_abcdefghijklmnopqrstuv03",
		strings.NewReader(string(requestBody)),
	)
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusBadGateway {
		t.Fatalf("exhausted registration retry returned %d", response.StatusCode)
	}

	upstream.mu.Lock()
	attempts := upstream.attempts
	upstream.mu.Unlock()
	if attempts != defaultDialAttempts {
		t.Fatalf("backend registration retry used %d attempts, expected %d", attempts, defaultDialAttempts)
	}
}

func TestSessionCreationRebindsBrowserOriginToInternalDialOrigin(t *testing.T) {
	testCases := []struct {
		kind      string
		sessionID string
		secret    string
	}{
		{"logs", "psw_abcdefghijklmnopqrstuv00", "0023456789abcdefghijklmnopqrstuvwxyzABCDEFGH"},
		{"terminal", "psw_abcdefghijklmnopqrstuv01", "1023456789abcdefghijklmnopqrstuvwxyzABCDEFGH"},
	}

	for _, testCase := range testCases {
		t.Run(testCase.kind, func(t *testing.T) {
			upstream := newUpstreamRecorderWithOriginCheck(t, true)
			defer upstream.close()
			_, server := newTestBroker(t, upstream)

			brokerTarget, err := url.Parse(server.URL)
			if err != nil {
				t.Fatal(err)
			}
			requestBody, _ := json.Marshal(createSessionRequest{
				Secret: testCase.secret,
				Kind:   testCase.kind,
				Target: "ws://" + brokerTarget.Host + "/v1/exec",
				Token:  "valid-token",
			})
			request, _ := http.NewRequest(
				http.MethodPost,
				server.URL+sessionPathPrefix+testCase.sessionID,
				strings.NewReader(string(requestBody)),
			)
			request.Header.Set("Content-Type", "application/json")
			request.Header.Set("Origin", server.URL)
			response, err := http.DefaultClient.Do(request)
			if err != nil {
				t.Fatal(err)
			}
			defer response.Body.Close()
			if response.StatusCode != http.StatusCreated {
				body, _ := io.ReadAll(response.Body)
				t.Fatalf("create returned %d: %s", response.StatusCode, body)
			}

			upstreamTarget, err := url.Parse(upstream.server.URL)
			if err != nil {
				t.Fatal(err)
			}
			upstream.mu.Lock()
			origins := append([]string(nil), upstream.origins...)
			upstream.mu.Unlock()
			if len(origins) != 1 || origins[0] != "http://"+upstreamTarget.Host {
				t.Fatalf("upstream origin was not rebound to the fixed dial origin: %#v", origins)
			}
		})
	}
}

func (recorder *upstreamRecorder) close() {
	recorder.server.Close()
}

func newTestBroker(t *testing.T, upstream *upstreamRecorder) (*broker, *httptest.Server) {
	t.Helper()
	cfg := brokerConfig{
		ListenAddress:   ":0",
		UpstreamURL:     upstream.server.URL,
		SessionDialURL:  upstream.server.URL,
		MaxSessions:     8,
		ReplayBytes:     128 * 1024,
		ActiveTTL:       time.Hour,
		HistoryTTL:      time.Hour,
		CleanupInterval: time.Hour,
	}
	instance, err := newBroker(cfg, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(instance)
	t.Cleanup(func() {
		server.Close()
		instance.close()
	})
	return instance, server
}

func createSession(t *testing.T, serverURL, upstreamURL, sessionID, secret, kind string) {
	t.Helper()
	upstreamTarget, _ := url.Parse(upstreamURL)
	brokerTarget, _ := url.Parse(serverURL)
	requestBody, _ := json.Marshal(createSessionRequest{
		Secret: secret,
		Kind:   kind,
		Target: "ws://" + brokerTarget.Host + "/v1/exec",
		Token:  "valid-token",
	})
	request, _ := http.NewRequest(http.MethodPost, serverURL+sessionPathPrefix+sessionID, strings.NewReader(string(requestBody)))
	request.Host = brokerTarget.Host
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(response.Body)
		t.Fatalf("create returned %d: %s (upstream %s)", response.StatusCode, body, upstreamTarget.Host)
	}
}

func attachClient(t *testing.T, serverURL, sessionID, secret, clientID string) *websocket.Conn {
	t.Helper()
	target := "ws" + strings.TrimPrefix(serverURL, "http") + sessionPathPrefix + sessionID
	dialer := *websocket.DefaultDialer
	dialer.Subprotocols = []string{
		consoleSubprotocol,
		secretProtocolPrefix + secret,
		clientProtocolPrefix + clientID,
	}
	connection, response, err := dialer.Dial(target, nil)
	if err != nil {
		t.Fatal(err)
	}
	if response == nil || response.Header.Get("Sec-WebSocket-Protocol") != consoleSubprotocol {
		t.Fatalf("broker did not select the console subprotocol: %#v", response)
	}
	t.Cleanup(func() { _ = connection.Close() })
	return connection
}

func readFrame(t *testing.T, connection *websocket.Conn) map[string]any {
	t.Helper()
	_ = connection.SetReadDeadline(time.Now().Add(3 * time.Second))
	_, payload, err := connection.ReadMessage()
	if err != nil {
		t.Fatal(err)
	}
	var frame map[string]any
	if err := json.Unmarshal(payload, &frame); err != nil {
		t.Fatal(err)
	}
	return frame
}

func readUntilType(t *testing.T, connection *websocket.Conn, frameType string) map[string]any {
	t.Helper()
	for i := 0; i < 10; i++ {
		frame := readFrame(t, connection)
		if frame["type"] == frameType {
			return frame
		}
	}
	t.Fatalf("did not receive frame type %s", frameType)
	return nil
}

func TestSessionSurvivesBrowserDisconnectAndReplaysOutput(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuvwx"
	secret := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, sessionID, secret, "terminal")

	first := attachClient(t, server.URL, sessionID, secret, "tab_abcdefghijklmnopqrstuvwx")
	readUntilType(t, first, "hello")
	readUntilType(t, first, "replay")
	_ = first.Close()

	firstOutput := base64.StdEncoding.EncodeToString([]byte("still running\n"))
	upstream.output <- firstOutput
	time.Sleep(50 * time.Millisecond)

	second := attachClient(t, server.URL, sessionID, secret, "tab_zyxwvutsrqponmlkjihgfedc")
	hello := readUntilType(t, second, "hello")
	if hello["status"] != "connected" {
		t.Fatalf("unexpected status: %v", hello["status"])
	}
	replay := readUntilType(t, second, "replay")
	entries := replay["replay"].([]any)
	if len(entries) != 1 || entries[0].(map[string]any)["data"] != firstOutput {
		t.Fatalf("unexpected replay: %#v", replay)
	}
}

func TestMultipleClientsReceiveSynchronizedOutputAndOneControlsInput(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuvwy"
	secret := "1123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, sessionID, secret, "terminal")

	firstID := "tab_abcdefghijklmnopqrstuvw1"
	secondID := "tab_abcdefghijklmnopqrstuvw2"
	first := attachClient(t, server.URL, sessionID, secret, firstID)
	firstHello := readUntilType(t, first, "hello")
	second := attachClient(t, server.URL, sessionID, secret, secondID)
	secondHello := readUntilType(t, second, "hello")
	if firstHello["controllerId"] != firstID || secondHello["controllerId"] != firstID {
		t.Fatalf("first browser tab did not retain control: %#v %#v", firstHello, secondHello)
	}

	output := base64.StdEncoding.EncodeToString([]byte("shared\n"))
	upstream.output <- output
	if readUntilType(t, first, "output")["data"] != output {
		t.Fatal("first client output mismatch")
	}
	if readUntilType(t, second, "output")["data"] != output {
		t.Fatal("second client output mismatch")
	}

	deniedInput := base64.StdEncoding.EncodeToString([]byte("denied"))
	allowedInput := base64.StdEncoding.EncodeToString([]byte("allowed"))
	payload, _ := json.Marshal(clientFrame{Type: "input", Data: deniedInput})
	_ = second.WriteMessage(websocket.TextMessage, payload)
	payload, _ = json.Marshal(clientFrame{Type: "input", Data: allowedInput})
	_ = first.WriteMessage(websocket.TextMessage, payload)

	deadline := time.Now().Add(2 * time.Second)
	for {
		upstream.mu.Lock()
		inputs := append([]string(nil), upstream.inputs...)
		upstream.mu.Unlock()
		if len(inputs) > 0 {
			if len(inputs) != 1 || inputs[0] != allowedInput {
				t.Fatalf("unexpected upstream input: %#v", inputs)
			}
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("controller input was not forwarded")
		}
		time.Sleep(10 * time.Millisecond)
	}

	claim, _ := json.Marshal(clientFrame{Type: "claim"})
	_ = second.WriteMessage(websocket.TextMessage, claim)
	control := readUntilType(t, second, "control")
	if control["controllerId"] != secondID {
		t.Fatalf("control was not transferred: %#v", control)
	}
}

func TestCreationRejectsForeignTargetAndSecretsAreRequired(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuvwz"
	secret := "2123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	requestBody, _ := json.Marshal(createSessionRequest{
		Secret: secret,
		Kind:   "logs",
		Target: "ws://example.invalid/v1/exec",
		Token:  "valid-token",
	})
	response, err := http.Post(
		server.URL+sessionPathPrefix+sessionID,
		"application/json",
		strings.NewReader(string(requestBody)),
	)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("foreign target returned %d", response.StatusCode)
	}

	target := "ws" + strings.TrimPrefix(server.URL, "http") + sessionPathPrefix + sessionID
	dialer := *websocket.DefaultDialer
	dialer.Subprotocols = []string{
		consoleSubprotocol,
		secretProtocolPrefix + "wrong-secret",
		clientProtocolPrefix + "tab_abcdefghijklmnopqrstuvw3",
	}
	if connection, response, err := dialer.Dial(target, nil); err == nil {
		_ = connection.Close()
		t.Fatal("missing session unexpectedly attached")
	} else if response == nil || response.StatusCode != http.StatusNotFound {
		t.Fatalf("unexpected missing-session response: %#v %v", response, err)
	}
}

func TestValidatedTargetRebuildsURLOnFixedDialOrigin(t *testing.T) {
	dialURL, err := url.Parse("https://127.0.0.1:9443/internal")
	if err != nil {
		t.Fatal(err)
	}
	instance := &broker{sessionDialURL: dialURL}
	request := httptest.NewRequest(http.MethodPost, "https://control.example/v1/exec/sessions", nil)
	request.Host = "control.example"

	target, err := instance.validatedTarget(
		request,
		"wss://control.example/v1/containers/1?action=execute&token=untrusted",
		"trusted-token",
	)
	if err != nil {
		t.Fatal(err)
	}
	if target.Scheme != "wss" || target.Host != "127.0.0.1:9443" {
		t.Fatalf("target did not use fixed dial origin: %s", target)
	}
	if target.Path != "/v1/containers/1" || target.Query().Get("action") != "execute" {
		t.Fatalf("legitimate target path or query was not preserved: %s", target)
	}
	if target.Query().Get("token") != "trusted-token" {
		t.Fatalf("untrusted token was not replaced: %s", target)
	}
}

func TestEdgeProxyBrokerAndApplicationWebSocketChain(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	instance, brokerServer := newTestBroker(t, upstream)

	brokerTarget, err := url.Parse(brokerServer.URL)
	if err != nil {
		t.Fatal(err)
	}
	edgeProxy := httputil.NewSingleHostReverseProxy(brokerTarget)
	edgeServer := httptest.NewServer(edgeProxy)
	defer edgeServer.Close()

	edgeTarget, err := url.Parse(edgeServer.URL)
	if err != nil {
		t.Fatal(err)
	}
	instance.sessionDialURL = edgeTarget

	sessionID := "psw_abcdefghijklmnopqrstuv10"
	secret := "3123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, edgeServer.URL, upstream.server.URL, sessionID, secret, "logs")
	connection := attachClient(t, edgeServer.URL, sessionID, secret, "tab_abcdefghijklmnopqrstuvw4")
	if frame := readUntilType(t, connection, "hello"); frame["status"] != "connected" {
		t.Fatalf("unexpected status through proxy chain: %#v", frame)
	}

	output := "01[2026-07-26T09:48:35Z] proxied log line\n"
	upstream.output <- output
	if frame := readUntilType(t, connection, "output"); frame["data"] != output {
		t.Fatalf("unexpected proxied output: %#v", frame)
	}
}

func TestLogPayloadPreservesApplicationWebSocketFraming(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuv11"
	secret := "4123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, sessionID, secret, "logs")

	connection := attachClient(t, server.URL, sessionID, secret, "tab_abcdefghijklmnopqrstuvw5")
	readUntilType(t, connection, "hello")
	readUntilType(t, connection, "replay")

	output := "02[2026-07-26T09:48:35Z] raw stderr frame\n"
	upstream.output <- output
	frame := readUntilType(t, connection, "output")
	if frame["data"] != output {
		t.Fatalf("raw log payload changed: %#v", frame)
	}
}

func TestStatusAndTerminationAcceptSecretHeader(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuv12"
	secret := "5123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, sessionID, secret, "terminal")

	statusRequest, _ := http.NewRequest(http.MethodGet, server.URL+sessionPathPrefix+sessionID, nil)
	statusRequest.Header.Set("X-PastureStack-Session-Secret", secret)
	statusResponse, err := http.DefaultClient.Do(statusRequest)
	if err != nil {
		t.Fatal(err)
	}
	defer statusResponse.Body.Close()
	if statusResponse.StatusCode != http.StatusOK {
		t.Fatalf("status returned %d", statusResponse.StatusCode)
	}

	deniedRequest, _ := http.NewRequest(http.MethodDelete, server.URL+sessionPathPrefix+sessionID, nil)
	deniedRequest.Header.Set("X-PastureStack-Session-Secret", "wrong-secret")
	deniedResponse, err := http.DefaultClient.Do(deniedRequest)
	if err != nil {
		t.Fatal(err)
	}
	defer deniedResponse.Body.Close()
	if deniedResponse.StatusCode != http.StatusForbidden {
		t.Fatalf("wrong secret returned %d", deniedResponse.StatusCode)
	}

	deleteRequest, _ := http.NewRequest(http.MethodDelete, server.URL+sessionPathPrefix+sessionID, nil)
	deleteRequest.Header.Set("X-PastureStack-Session-Secret", secret)
	deleteResponse, err := http.DefaultClient.Do(deleteRequest)
	if err != nil {
		t.Fatal(err)
	}
	defer deleteResponse.Body.Close()
	if deleteResponse.StatusCode != http.StatusNoContent {
		t.Fatalf("delete returned %d", deleteResponse.StatusCode)
	}
}

func TestMissingSessionStatusIsARecoverableState(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)

	statusRequest, _ := http.NewRequest(
		http.MethodGet,
		server.URL+sessionPathPrefix+"psw_abcdefghijklmnopqrstuv99",
		nil,
	)
	statusRequest.Header.Set(
		"X-PastureStack-Session-Secret",
		"5123456789abcdefghijklmnopqrstuvwxyzABCDEFGH",
	)
	statusResponse, err := http.DefaultClient.Do(statusRequest)
	if err != nil {
		t.Fatal(err)
	}
	defer statusResponse.Body.Close()
	if statusResponse.StatusCode != http.StatusOK {
		t.Fatalf("missing status returned %d", statusResponse.StatusCode)
	}
	if statusResponse.Header.Get("Cache-Control") != "no-store" {
		t.Fatalf("missing status was cacheable: %q", statusResponse.Header.Get("Cache-Control"))
	}
	var response map[string]string
	if err := json.NewDecoder(statusResponse.Body).Decode(&response); err != nil {
		t.Fatal(err)
	}
	if response["status"] != "missing" {
		t.Fatalf("unexpected missing status response: %#v", response)
	}
}

func TestCreationRejectsCrossOriginRequest(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuv13"
	secret := "6123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	requestBody, _ := json.Marshal(createSessionRequest{
		Secret: secret,
		Kind:   "terminal",
		Target: "ws://example.invalid/v1/exec",
		Token:  "valid-token",
	})
	request, _ := http.NewRequest(
		http.MethodPost,
		server.URL+sessionPathPrefix+sessionID,
		strings.NewReader(string(requestBody)),
	)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Origin", "https://example.invalid")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusForbidden {
		t.Fatalf("cross-origin creation returned %d", response.StatusCode)
	}
}

func TestEndedSessionFreesConcurrentSessionCapacity(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	instance, server := newTestBroker(t, upstream)
	instance.config.MaxSessions = 1

	firstID := "psw_abcdefghijklmnopqrstuv14"
	firstSecret := "7123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, firstID, firstSecret, "terminal")

	deleteRequest, _ := http.NewRequest(http.MethodDelete, server.URL+sessionPathPrefix+firstID, nil)
	deleteRequest.Header.Set("X-PastureStack-Session-Secret", firstSecret)
	deleteResponse, err := http.DefaultClient.Do(deleteRequest)
	if err != nil {
		t.Fatal(err)
	}
	defer deleteResponse.Body.Close()
	if deleteResponse.StatusCode != http.StatusNoContent {
		t.Fatalf("delete returned %d", deleteResponse.StatusCode)
	}

	createSession(
		t,
		server.URL,
		upstream.server.URL,
		"psw_abcdefghijklmnopqrstuv15",
		"8123456789abcdefghijklmnopqrstuvwxyzABCDEFGH",
		"terminal",
	)
}

func TestAttachRequiresNamedConsoleSubprotocol(t *testing.T) {
	upstream := newUpstreamRecorder(t)
	defer upstream.close()
	_, server := newTestBroker(t, upstream)
	sessionID := "psw_abcdefghijklmnopqrstuv16"
	secret := "9123456789abcdefghijklmnopqrstuvwxyzABCDEFGH"
	createSession(t, server.URL, upstream.server.URL, sessionID, secret, "terminal")

	target := "ws" + strings.TrimPrefix(server.URL, "http") + sessionPathPrefix + sessionID
	connection, response, err := websocket.DefaultDialer.Dial(target, nil)
	if err == nil {
		_ = connection.Close()
		t.Fatal("attach without console subprotocol unexpectedly succeeded")
	}
	if response == nil || response.StatusCode != http.StatusBadRequest {
		t.Fatalf("unexpected missing-subprotocol response: %#v %v", response, err)
	}
}

func TestPlatformAPIResponsesCannotBeSharedCached(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Cache-Control", "public,s-maxage=86400")
		writer.Header().Set("Age", "120")
		_, _ = io.WriteString(writer, request.URL.Path)
	}))
	defer upstream.Close()

	cfg := brokerConfig{
		ListenAddress:   ":0",
		UpstreamURL:     upstream.URL,
		SessionDialURL:  upstream.URL,
		MaxSessions:     8,
		ReplayBytes:     128 * 1024,
		ActiveTTL:       time.Hour,
		HistoryTTL:      time.Hour,
		CleanupInterval: time.Hour,
	}
	instance, err := newBroker(cfg, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	defer instance.close()

	for _, path := range []string{"/v2-beta/accounts", "/v1-auth/config", "/v3/schema"} {
		response := httptest.NewRecorder()
		instance.ServeHTTP(response, httptest.NewRequest(http.MethodGet, path, nil))
		if got := response.Header().Get("Cache-Control"); got != "private, no-store" {
			t.Fatalf("API response %s remained shared-cacheable: %q", path, got)
		}
		if got := response.Header().Get("Pragma"); got != "no-cache" {
			t.Fatalf("API response %s lacks legacy no-cache protection: %q", path, got)
		}
		if got := response.Header().Get("Expires"); got != "0" {
			t.Fatalf("API response %s lacks an immediate expiry: %q", path, got)
		}
		if got := response.Header().Get("Age"); got != "" {
			t.Fatalf("API response %s retained an upstream cache age: %q", path, got)
		}
	}
}

func TestStaticAssetCachePolicyIsPreserved(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Cache-Control", "public,max-age=31536000,immutable")
		_, _ = io.WriteString(writer, "asset")
	}))
	defer upstream.Close()

	cfg := brokerConfig{
		ListenAddress:   ":0",
		UpstreamURL:     upstream.URL,
		SessionDialURL:  upstream.URL,
		MaxSessions:     8,
		ReplayBytes:     128 * 1024,
		ActiveTTL:       time.Hour,
		HistoryTTL:      time.Hour,
		CleanupInterval: time.Hour,
	}
	instance, err := newBroker(cfg, log.New(io.Discard, "", 0))
	if err != nil {
		t.Fatal(err)
	}
	defer instance.close()

	response := httptest.NewRecorder()
	instance.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/assets/app.js", nil))
	if got := response.Header().Get("Cache-Control"); got != "public,max-age=31536000,immutable" {
		t.Fatalf("static asset cache policy changed unexpectedly: %q", got)
	}
}
