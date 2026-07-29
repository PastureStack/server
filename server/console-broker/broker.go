package main

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	sessionPathPrefix    = "/v1/exec/sessions/"
	healthPath           = "/v1/exec/sessions/healthz"
	consoleSubprotocol   = "pasturestack-console-v1"
	secretProtocolPrefix = "pasturestack-secret."
	clientProtocolPrefix = "pasturestack-client."
	maxCreateBody        = 128 * 1024
	maxClientFrame       = 96 * 1024
	maxUpstreamFrame     = 4 * 1024 * 1024
	clientQueueSize      = 256
	writeWait            = 10 * time.Second
	pongWait             = 60 * time.Second
	pingPeriod           = 25 * time.Second
)

var (
	sessionIDPattern = regexp.MustCompile(`^psw_[A-Za-z0-9_-]{20,96}$`)
	clientIDPattern  = regexp.MustCompile(`^tab_[A-Za-z0-9_-]{20,96}$`)
	secretPattern    = regexp.MustCompile(`^[A-Za-z0-9_-]{40,256}$`)
)

type brokerConfig struct {
	ListenAddress   string
	UpstreamURL     string
	SessionDialURL  string
	MaxSessions     int
	ReplayBytes     int
	ActiveTTL       time.Duration
	HistoryTTL      time.Duration
	CleanupInterval time.Duration
}

type broker struct {
	config         brokerConfig
	logger         *log.Logger
	upstreamURL    *url.URL
	sessionDialURL *url.URL
	reverseProxy   *httputil.ReverseProxy
	upgrader       websocket.Upgrader

	mu       sync.RWMutex
	sessions map[string]*brokerSession
	stop     chan struct{}
	done     chan struct{}
}

type brokerSession struct {
	id         string
	secretHash [sha256.Size]byte
	kind       string
	createdAt  time.Time

	mu            sync.Mutex
	upstream      *websocket.Conn
	upstreamWrite sync.Mutex
	clients       map[string]*brokerClient
	controllerID  string
	status        string
	lastActivity  time.Time
	endedAt       time.Time
	sequence      uint64
	replay        []outputFrame
	replayBytes   int
	replayLimit   int
	closeOnce     sync.Once
}

type brokerClient struct {
	id      string
	conn    *websocket.Conn
	send    chan []byte
	done    chan struct{}
	close   sync.Once
	session *brokerSession
}

type createSessionRequest struct {
	Secret string `json:"secret"`
	Kind   string `json:"kind"`
	Target string `json:"target"`
	Token  string `json:"token"`
}

type clientFrame struct {
	Type string `json:"type"`
	Data string `json:"data,omitempty"`
	Cols int    `json:"cols,omitempty"`
	Rows int    `json:"rows,omitempty"`
}

type outputFrame struct {
	Sequence uint64 `json:"sequence"`
	Data     string `json:"data"`
}

type helloFrame struct {
	Type         string    `json:"type"`
	Status       string    `json:"status"`
	ControllerID string    `json:"controllerId,omitempty"`
	LastActivity time.Time `json:"lastActivity"`
}

type replayFrame struct {
	Type   string        `json:"type"`
	Replay []outputFrame `json:"replay"`
}

type statusFrame struct {
	Type         string    `json:"type"`
	Status       string    `json:"status"`
	ControllerID string    `json:"controllerId,omitempty"`
	LastActivity time.Time `json:"lastActivity"`
}

type controlFrame struct {
	Type         string `json:"type"`
	ControllerID string `json:"controllerId,omitempty"`
}

type errorFrame struct {
	Type    string `json:"type"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

func newBroker(cfg brokerConfig, logger *log.Logger) (*broker, error) {
	upstreamURL, err := url.Parse(cfg.UpstreamURL)
	if err != nil {
		return nil, fmt.Errorf("parse upstream URL: %w", err)
	}
	if upstreamURL.Scheme != "http" && upstreamURL.Scheme != "https" {
		return nil, errors.New("upstream URL must use http or https")
	}
	if upstreamURL.Host == "" {
		return nil, errors.New("upstream URL must include a host")
	}
	sessionDialURL, err := url.Parse(cfg.SessionDialURL)
	if err != nil {
		return nil, fmt.Errorf("parse session dial URL: %w", err)
	}
	if sessionDialURL.Scheme != "http" && sessionDialURL.Scheme != "https" {
		return nil, errors.New("session dial URL must use http or https")
	}
	if sessionDialURL.Host == "" {
		return nil, errors.New("session dial URL must include a host")
	}

	proxy := httputil.NewSingleHostReverseProxy(upstreamURL)
	originalDirector := proxy.Director
	proxy.Director = func(request *http.Request) {
		originalHost := request.Host
		originalDirector(request)
		request.Host = originalHost
		request.Header.Set("X-Forwarded-Host", originalHost)
		if request.TLS == nil {
			request.Header.Set("X-Forwarded-Proto", "http")
		} else {
			request.Header.Set("X-Forwarded-Proto", "https")
		}
	}
	proxy.FlushInterval = -1
	proxy.ErrorHandler = func(writer http.ResponseWriter, request *http.Request, proxyErr error) {
		logger.Printf("application proxy failed for %s: %v", safeRequestPath(request), proxyErr)
		http.Error(writer, "PastureStack application service is not ready", http.StatusBadGateway)
	}

	result := &broker{
		config:         cfg,
		logger:         logger,
		upstreamURL:    upstreamURL,
		sessionDialURL: sessionDialURL,
		reverseProxy:   proxy,
		sessions:       make(map[string]*brokerSession),
		stop:           make(chan struct{}),
		done:           make(chan struct{}),
		upgrader: websocket.Upgrader{
			HandshakeTimeout: 10 * time.Second,
			ReadBufferSize:   16 * 1024,
			WriteBufferSize:  16 * 1024,
			CheckOrigin:      sameOrigin,
			Subprotocols:     []string{consoleSubprotocol},
		},
	}
	go result.cleanupLoop()
	return result, nil
}

func (b *broker) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if request.URL.Path == healthPath {
		writer.Header().Set("Content-Type", "application/json")
		writer.Header().Set("Cache-Control", "no-store")
		_, _ = io.WriteString(writer, `{"status":"ok"}`+"\n")
		return
	}

	if !strings.HasPrefix(request.URL.Path, sessionPathPrefix) {
		b.reverseProxy.ServeHTTP(writer, request)
		return
	}

	sessionID := strings.TrimPrefix(request.URL.Path, sessionPathPrefix)
	if strings.Contains(sessionID, "/") || !sessionIDPattern.MatchString(sessionID) {
		writeJSONError(writer, http.StatusBadRequest, "invalid_session_id", "Invalid console session identifier")
		return
	}

	switch request.Method {
	case http.MethodPost:
		b.createSession(writer, request, sessionID)
	case http.MethodGet:
		if websocket.IsWebSocketUpgrade(request) {
			b.attachSession(writer, request, sessionID)
		} else {
			b.sessionStatus(writer, request, sessionID)
		}
	case http.MethodDelete:
		b.terminateSession(writer, request, sessionID)
	default:
		writer.Header().Set("Allow", "GET, POST, DELETE")
		writeJSONError(writer, http.StatusMethodNotAllowed, "method_not_allowed", "Method not allowed")
	}
}

func (b *broker) createSession(writer http.ResponseWriter, request *http.Request, sessionID string) {
	if !requestOriginAllowed(request) {
		writeJSONError(writer, http.StatusForbidden, "origin_denied", "Cross-origin session creation is not allowed")
		return
	}

	body := http.MaxBytesReader(writer, request.Body, maxCreateBody)
	defer body.Close()
	decoder := json.NewDecoder(body)
	decoder.DisallowUnknownFields()
	var input createSessionRequest
	if err := decoder.Decode(&input); err != nil {
		writeJSONError(writer, http.StatusBadRequest, "invalid_request", "Invalid session creation request")
		return
	}
	if err := validateSessionCredentials(sessionID, input.Secret, input.Kind); err != nil {
		writeJSONError(writer, http.StatusBadRequest, "invalid_request", err.Error())
		return
	}
	if len(input.Token) < 8 || len(input.Token) > 16*1024 {
		writeJSONError(writer, http.StatusBadRequest, "invalid_token", "Invalid upstream access token")
		return
	}

	secretHash := sha256.Sum256([]byte(input.Secret))
	if existing := b.lookupSession(sessionID); existing != nil {
		if !existing.matchesSecret(secretHash) {
			writeJSONError(writer, http.StatusConflict, "session_conflict", "Console session identifier is already in use")
			return
		}
		writeSessionCreated(writer, http.StatusOK, existing)
		return
	}
	if b.activeSessionCount() >= b.config.MaxSessions {
		writeJSONError(writer, http.StatusTooManyRequests, "session_limit", "Console session limit reached")
		return
	}

	target, err := b.validatedTarget(request, input.Target, input.Token)
	if err != nil {
		writeJSONError(writer, http.StatusBadRequest, "invalid_target", err.Error())
		return
	}

	headers := http.Header{}
	if origin := request.Header.Get("Origin"); origin != "" {
		headers.Set("Origin", origin)
	}
	upstream, response, err := websocket.DefaultDialer.Dial(target.String(), headers)
	if response != nil && response.Body != nil {
		_ = response.Body.Close()
	}
	if err != nil {
		b.logger.Printf("upstream session connection failed for %s: %v", sessionID, err)
		writeJSONError(writer, http.StatusBadGateway, "upstream_unavailable", "Unable to start the console session")
		return
	}

	now := time.Now().UTC()
	upstream.SetReadLimit(maxUpstreamFrame)
	session := &brokerSession{
		id:           sessionID,
		secretHash:   secretHash,
		kind:         input.Kind,
		createdAt:    now,
		upstream:     upstream,
		clients:      make(map[string]*brokerClient),
		status:       "connected",
		lastActivity: now,
		replayLimit:  b.config.ReplayBytes,
	}

	b.mu.Lock()
	if existing := b.sessions[sessionID]; existing != nil {
		b.mu.Unlock()
		_ = upstream.Close()
		if !existing.matchesSecret(secretHash) {
			writeJSONError(writer, http.StatusConflict, "session_conflict", "Console session identifier is already in use")
			return
		}
		writeSessionCreated(writer, http.StatusOK, existing)
		return
	}
	if b.activeSessionCountLocked() >= b.config.MaxSessions {
		b.mu.Unlock()
		_ = upstream.Close()
		writeJSONError(writer, http.StatusTooManyRequests, "session_limit", "Console session limit reached")
		return
	}
	b.sessions[sessionID] = session
	b.mu.Unlock()

	go session.readUpstream(b, upstream)
	writeSessionCreated(writer, http.StatusCreated, session)
}

func (b *broker) attachSession(writer http.ResponseWriter, request *http.Request, sessionID string) {
	if !hasWebsocketProtocol(request, consoleSubprotocol) {
		writeJSONError(writer, http.StatusBadRequest, "invalid_subprotocol", "Console WebSocket subprotocol is required")
		return
	}
	session := b.lookupSession(sessionID)
	if session == nil {
		writeJSONError(writer, http.StatusNotFound, "session_not_found", "Console session was not found")
		return
	}
	secret := websocketCredential(request, secretProtocolPrefix)
	secretHash := sha256.Sum256([]byte(secret))
	if !session.matchesSecret(secretHash) {
		writeJSONError(writer, http.StatusForbidden, "secret_denied", "Console session access was denied")
		return
	}
	clientID := websocketCredential(request, clientProtocolPrefix)
	if !clientIDPattern.MatchString(clientID) {
		writeJSONError(writer, http.StatusBadRequest, "invalid_client_id", "Invalid browser tab identifier")
		return
	}

	connection, err := b.upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}
	client := &brokerClient{
		id:      clientID,
		conn:    connection,
		send:    make(chan []byte, clientQueueSize),
		done:    make(chan struct{}),
		session: session,
	}
	session.attachClient(client)
	go client.writeLoop()
	client.readLoop()
}

func (b *broker) sessionStatus(writer http.ResponseWriter, request *http.Request, sessionID string) {
	session := b.lookupSession(sessionID)
	if session == nil {
		writeJSONError(writer, http.StatusNotFound, "session_not_found", "Console session was not found")
		return
	}
	secretHash := sha256.Sum256([]byte(sessionSecret(request)))
	if !session.matchesSecret(secretHash) {
		writeJSONError(writer, http.StatusForbidden, "secret_denied", "Console session access was denied")
		return
	}

	session.mu.Lock()
	response := map[string]any{
		"sessionId":    session.id,
		"kind":         session.kind,
		"status":       session.status,
		"controllerId": session.controllerID,
		"clientCount":  len(session.clients),
		"replayFrames": len(session.replay),
		"lastActivity": session.lastActivity,
		"createdAt":    session.createdAt,
	}
	session.mu.Unlock()

	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cache-Control", "no-store")
	_ = json.NewEncoder(writer).Encode(response)
}

func (b *broker) terminateSession(writer http.ResponseWriter, request *http.Request, sessionID string) {
	if !requestOriginAllowed(request) {
		writeJSONError(writer, http.StatusForbidden, "origin_denied", "Cross-origin session termination is not allowed")
		return
	}
	session := b.lookupSession(sessionID)
	if session == nil {
		writer.WriteHeader(http.StatusNoContent)
		return
	}
	secretHash := sha256.Sum256([]byte(sessionSecret(request)))
	if !session.matchesSecret(secretHash) {
		writeJSONError(writer, http.StatusForbidden, "secret_denied", "Console session access was denied")
		return
	}

	session.end("ended")
	writer.WriteHeader(http.StatusNoContent)
}

func (b *broker) validatedTarget(request *http.Request, rawTarget, token string) (*url.URL, error) {
	if len(rawTarget) < 8 || len(rawTarget) > 16*1024 {
		return nil, errors.New("invalid upstream target")
	}
	target, err := url.Parse(rawTarget)
	if err != nil {
		return nil, errors.New("invalid upstream target")
	}
	if target.Scheme != "ws" && target.Scheme != "wss" {
		return nil, errors.New("upstream target must use WebSocket")
	}
	if target.Host == "" || target.User != nil || target.Fragment != "" {
		return nil, errors.New("invalid upstream target")
	}
	if !sameHost(target.Host, request.Host) {
		return nil, errors.New("upstream target must match the current PastureStack server")
	}
	if !strings.HasPrefix(target.EscapedPath(), "/v1/") ||
		strings.HasPrefix(target.EscapedPath(), sessionPathPrefix) {
		return nil, errors.New("upstream target path is not allowed")
	}

	internal := *target
	if b.sessionDialURL.Scheme == "https" {
		internal.Scheme = "wss"
	} else {
		internal.Scheme = "ws"
	}
	internal.Host = b.sessionDialURL.Host
	query := internal.Query()
	query.Set("token", token)
	internal.RawQuery = query.Encode()
	return &internal, nil
}

func (b *broker) lookupSession(sessionID string) *brokerSession {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.sessions[sessionID]
}

func (b *broker) activeSessionCount() int {
	b.mu.RLock()
	defer b.mu.RUnlock()
	return b.activeSessionCountLocked()
}

func (b *broker) activeSessionCountLocked() int {
	count := 0
	for _, session := range b.sessions {
		session.mu.Lock()
		status := session.status
		session.mu.Unlock()
		if status != "ended" && status != "error" {
			count++
		}
	}
	return count
}

func (b *broker) cleanupLoop() {
	ticker := time.NewTicker(b.config.CleanupInterval)
	defer func() {
		ticker.Stop()
		close(b.done)
	}()
	for {
		select {
		case now := <-ticker.C:
			b.cleanup(now.UTC())
		case <-b.stop:
			return
		}
	}
}

func (b *broker) cleanup(now time.Time) {
	var expired []*brokerSession
	b.mu.Lock()
	for id, session := range b.sessions {
		session.mu.Lock()
		status := session.status
		lastActivity := session.lastActivity
		endedAt := session.endedAt
		session.mu.Unlock()

		remove := false
		if status == "ended" || status == "error" {
			remove = !endedAt.IsZero() && now.Sub(endedAt) >= b.config.HistoryTTL
		} else {
			remove = now.Sub(lastActivity) >= b.config.ActiveTTL
		}
		if remove {
			delete(b.sessions, id)
			expired = append(expired, session)
		}
	}
	b.mu.Unlock()

	for _, session := range expired {
		session.end("ended")
		session.closeClients()
	}
}

func (b *broker) close() {
	select {
	case <-b.stop:
	default:
		close(b.stop)
	}
	<-b.done

	b.mu.Lock()
	sessions := make([]*brokerSession, 0, len(b.sessions))
	for _, session := range b.sessions {
		sessions = append(sessions, session)
	}
	b.sessions = make(map[string]*brokerSession)
	b.mu.Unlock()

	for _, session := range sessions {
		session.end("ended")
		session.closeClients()
	}
}

func (session *brokerSession) matchesSecret(candidate [sha256.Size]byte) bool {
	return subtle.ConstantTimeCompare(session.secretHash[:], candidate[:]) == 1
}

func (session *brokerSession) attachClient(client *brokerClient) {
	session.mu.Lock()
	if previous := session.clients[client.id]; previous != nil {
		delete(session.clients, client.id)
		previous.shutdown()
	}
	session.clients[client.id] = client
	if session.kind == "terminal" && session.controllerID == "" && session.status == "connected" {
		session.controllerID = client.id
	}
	hello := helloFrame{
		Type:         "hello",
		Status:       session.status,
		ControllerID: session.controllerID,
		LastActivity: session.lastActivity,
	}
	replay := append([]outputFrame(nil), session.replay...)
	client.enqueueJSON(hello)
	client.enqueueJSON(replayFrame{Type: "replay", Replay: replay})
	session.broadcastJSONLocked(controlFrame{Type: "control", ControllerID: session.controllerID})
	session.mu.Unlock()
}

func (session *brokerSession) detachClient(client *brokerClient) {
	session.mu.Lock()
	if current := session.clients[client.id]; current == client {
		delete(session.clients, client.id)
	}
	if session.controllerID == client.id {
		session.controllerID = ""
		for id := range session.clients {
			session.controllerID = id
			break
		}
		session.broadcastJSONLocked(controlFrame{Type: "control", ControllerID: session.controllerID})
	}
	session.mu.Unlock()
	client.shutdown()
}

func (session *brokerSession) claimControl(client *brokerClient) {
	session.mu.Lock()
	if session.kind != "terminal" || session.status != "connected" {
		session.mu.Unlock()
		return
	}
	if current := session.clients[client.id]; current != client {
		session.mu.Unlock()
		return
	}
	session.controllerID = client.id
	session.broadcastJSONLocked(controlFrame{Type: "control", ControllerID: session.controllerID})
	session.mu.Unlock()
}

func (session *brokerSession) readUpstream(b *broker, upstream *websocket.Conn) {
	for {
		messageType, payload, err := upstream.ReadMessage()
		if err != nil {
			if !websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
				b.logger.Printf("upstream session %s ended: %v", session.id, err)
			}
			session.end("ended")
			return
		}
		if messageType != websocket.TextMessage && messageType != websocket.BinaryMessage {
			continue
		}
		session.recordOutput(string(payload))
	}
}

func (session *brokerSession) recordOutput(data string) {
	now := time.Now().UTC()
	session.mu.Lock()
	if session.status == "ended" || session.status == "error" {
		session.mu.Unlock()
		return
	}
	session.sequence++
	frame := outputFrame{Sequence: session.sequence, Data: data}
	session.lastActivity = now

	frameBytes := len(data) + 32
	if frameBytes <= session.replayLimit {
		session.replay = append(session.replay, frame)
		session.replayBytes += frameBytes
		for session.replayBytes > session.replayLimit && len(session.replay) > 0 {
			removed := session.replay[0]
			session.replay = session.replay[1:]
			session.replayBytes -= len(removed.Data) + 32
		}
	}
	session.broadcastJSONLocked(struct {
		Type string `json:"type"`
		outputFrame
	}{
		Type:        "output",
		outputFrame: frame,
	})
	session.mu.Unlock()
}

func (session *brokerSession) writeInput(client *brokerClient, data string) {
	session.mu.Lock()
	allowed := session.status == "connected" && session.controllerID == client.id &&
		session.clients[client.id] == client
	session.mu.Unlock()
	if !allowed || len(data) == 0 || len(data) > maxClientFrame {
		return
	}
	if _, err := base64.StdEncoding.DecodeString(data); err != nil {
		client.enqueueJSON(errorFrame{
			Type:    "error",
			Code:    "invalid_input",
			Message: "Terminal input was not valid base64 data",
		})
		return
	}
	session.touch()
	if err := session.writeUpstream(websocket.TextMessage, []byte(data)); err != nil {
		session.end("ended")
	}
}

func (session *brokerSession) resize(client *brokerClient, cols, rows int) {
	session.mu.Lock()
	allowed := session.kind == "terminal" && session.status == "connected" &&
		session.controllerID == client.id && session.clients[client.id] == client
	session.mu.Unlock()
	if !allowed || cols < 2 || cols > 1000 || rows < 2 || rows > 1000 {
		return
	}
	session.touch()
	payload := []byte(":resizeTTY:" + strconv.Itoa(cols) + "," + strconv.Itoa(rows))
	if err := session.writeUpstream(websocket.TextMessage, payload); err != nil {
		session.end("ended")
	}
}

func (session *brokerSession) touch() {
	session.mu.Lock()
	if session.status == "connected" {
		session.lastActivity = time.Now().UTC()
	}
	session.mu.Unlock()
}

func (session *brokerSession) writeUpstream(messageType int, payload []byte) error {
	session.upstreamWrite.Lock()
	defer session.upstreamWrite.Unlock()

	session.mu.Lock()
	upstream := session.upstream
	status := session.status
	session.mu.Unlock()
	if upstream == nil || status != "connected" {
		return errors.New("upstream session is not connected")
	}
	_ = upstream.SetWriteDeadline(time.Now().Add(writeWait))
	return upstream.WriteMessage(messageType, payload)
}

func (session *brokerSession) end(status string) {
	session.closeOnce.Do(func() {
		now := time.Now().UTC()
		session.mu.Lock()
		session.status = status
		session.lastActivity = now
		session.endedAt = now
		session.controllerID = ""
		upstream := session.upstream
		session.upstream = nil
		session.broadcastJSONLocked(statusFrame{
			Type:         "status",
			Status:       status,
			LastActivity: now,
		})
		session.mu.Unlock()

		if upstream != nil {
			session.upstreamWrite.Lock()
			_ = upstream.WriteControl(
				websocket.CloseMessage,
				websocket.FormatCloseMessage(websocket.CloseNormalClosure, "session ended"),
				time.Now().Add(writeWait),
			)
			_ = upstream.Close()
			session.upstreamWrite.Unlock()
		}
	})
}

func (session *brokerSession) closeClients() {
	session.mu.Lock()
	clients := make([]*brokerClient, 0, len(session.clients))
	for _, client := range session.clients {
		clients = append(clients, client)
	}
	session.clients = make(map[string]*brokerClient)
	session.controllerID = ""
	session.mu.Unlock()
	for _, client := range clients {
		client.shutdown()
	}
}

func (session *brokerSession) broadcastJSONLocked(value any) {
	payload, err := json.Marshal(value)
	if err != nil {
		return
	}
	for _, client := range session.clients {
		client.enqueue(payload)
	}
}

func (client *brokerClient) readLoop() {
	defer client.session.detachClient(client)
	client.conn.SetReadLimit(maxClientFrame)
	_ = client.conn.SetReadDeadline(time.Now().Add(pongWait))
	client.conn.SetPongHandler(func(string) error {
		return client.conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		_, payload, err := client.conn.ReadMessage()
		if err != nil {
			return
		}
		var frame clientFrame
		if err := json.Unmarshal(payload, &frame); err != nil {
			client.enqueueJSON(errorFrame{
				Type:    "error",
				Code:    "invalid_frame",
				Message: "Invalid console client frame",
			})
			continue
		}
		switch frame.Type {
		case "claim":
			client.session.claimControl(client)
		case "input":
			client.session.writeInput(client, frame.Data)
		case "resize":
			client.session.resize(client, frame.Cols, frame.Rows)
		}
	}
}

func (client *brokerClient) writeLoop() {
	ticker := time.NewTicker(pingPeriod)
	defer ticker.Stop()
	defer client.shutdown()
	for {
		select {
		case payload := <-client.send:
			_ = client.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := client.conn.WriteMessage(websocket.TextMessage, payload); err != nil {
				return
			}
		case <-ticker.C:
			_ = client.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := client.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		case <-client.done:
			return
		}
	}
}

func (client *brokerClient) enqueueJSON(value any) {
	payload, err := json.Marshal(value)
	if err == nil {
		client.enqueue(payload)
	}
}

func (client *brokerClient) enqueue(payload []byte) {
	select {
	case client.send <- payload:
	default:
		client.shutdown()
	}
}

func (client *brokerClient) shutdown() {
	client.close.Do(func() {
		close(client.done)
		_ = client.conn.Close()
	})
}

func validateSessionCredentials(sessionID, secret, kind string) error {
	if !sessionIDPattern.MatchString(sessionID) {
		return errors.New("invalid console session identifier")
	}
	if !secretPattern.MatchString(secret) {
		return errors.New("invalid console session secret")
	}
	if kind != "terminal" && kind != "logs" {
		return errors.New("console session kind must be terminal or logs")
	}
	return nil
}

func sessionSecret(request *http.Request) string {
	if secret := request.Header.Get("X-PastureStack-Session-Secret"); secret != "" {
		return secret
	}
	return request.URL.Query().Get("secret")
}

func websocketCredential(request *http.Request, prefix string) string {
	for _, protocol := range websocket.Subprotocols(request) {
		if strings.HasPrefix(protocol, prefix) {
			return strings.TrimPrefix(protocol, prefix)
		}
	}
	return ""
}

func hasWebsocketProtocol(request *http.Request, expected string) bool {
	for _, protocol := range websocket.Subprotocols(request) {
		if protocol == expected {
			return true
		}
	}
	return false
}

func requestOriginAllowed(request *http.Request) bool {
	origin := request.Header.Get("Origin")
	if origin == "" {
		return true
	}
	parsed, err := url.Parse(origin)
	return err == nil && sameHost(parsed.Host, request.Host)
}

func sameOrigin(request *http.Request) bool {
	return requestOriginAllowed(request)
}

func sameHost(left, right string) bool {
	leftHost, leftPort := splitHostPort(left)
	rightHost, rightPort := splitHostPort(right)
	return strings.EqualFold(leftHost, rightHost) && leftPort == rightPort
}

func splitHostPort(value string) (string, string) {
	host, port, err := net.SplitHostPort(value)
	if err == nil {
		return strings.Trim(strings.ToLower(host), "[]"), port
	}
	return strings.Trim(strings.ToLower(value), "[]"), ""
}

func safeRequestPath(request *http.Request) string {
	return request.Method + " " + request.URL.EscapedPath()
}

func writeSessionCreated(writer http.ResponseWriter, status int, session *brokerSession) {
	session.mu.Lock()
	response := map[string]any{
		"sessionId":    session.id,
		"kind":         session.kind,
		"status":       session.status,
		"lastActivity": session.lastActivity,
		"createdAt":    session.createdAt,
	}
	session.mu.Unlock()
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cache-Control", "no-store")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(response)
}

func writeJSONError(writer http.ResponseWriter, status int, code, message string) {
	writer.Header().Set("Content-Type", "application/json")
	writer.Header().Set("Cache-Control", "no-store")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(errorFrame{
		Type:    "error",
		Code:    code,
		Message: message,
	})
}
