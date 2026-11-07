package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"sync/atomic"
	"time"
	"unicode/utf8"

	"github.com/gorilla/websocket"
)

const boundedLogBytes = 64 * 1024

var logUUID = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

// Only the fixed private CLI reads this envelope. There is no HTTP route or GUI session.
type containerLogTicket struct {
	RequestID     string `json:"requestId"`
	ActorID       int64  `json:"actorId"`
	ProjectID     int64  `json:"projectId"`
	ContainerUUID string `json:"containerUuid"`
	Operation     string `json:"operation"`
	Expires       int64  `json:"expiresAtMillis"`
	Lines         int    `json:"tailLines"`
	Token         string `json:"token"`
	consumed      atomic.Bool
}

func (input *containerLogTicket) consume(now time.Time) error {
	if input == nil || !input.consumed.CompareAndSwap(false, true) || input.ActorID <= 0 || input.ProjectID <= 0 ||
		input.Operation != "logs" || !logUUID.MatchString(input.ContainerUUID) || len(input.RequestID) != 43 ||
		input.RequestID[:7] != "ailogs-" || !logUUID.MatchString(input.RequestID[7:]) || input.Lines < 1 || input.Lines > 200 ||
		input.Token == "" || len(input.Token) > 32768 || input.Expires <= now.UnixMilli() || input.Expires > now.Add(5*time.Second).UnixMilli() {
		return errors.New("bounded logs ticket denied")
	}
	return nil
}

type containerLogResult struct {
	RequestID     string `json:"requestId"`
	ActorID       int64  `json:"actorId"`
	ProjectID     int64  `json:"projectId"`
	ContainerUUID string `json:"containerUuid"`
	Operation     string `json:"operation"`
	Lines         int    `json:"tailLines"`
	Text          string `json:"text"`
	Truncated     bool   `json:"truncated"`
	Completeness  string `json:"completeness"`
	StopReason    string `json:"stopReason"`
}

func collectContainerLogs(ctx context.Context, connection *websocket.Conn, lines int) (string, bool, string, error) {
	defer connection.Close()
	// Native messages may exceed the output budget. Read only bounded payload
	// chunks, rather than allocating or rejecting a complete WebSocket message.
	connection.SetReadLimit(0)
	if deadline, ok := ctx.Deadline(); ok {
		_ = connection.SetReadDeadline(deadline)
	}
	done := make(chan struct{})
	defer close(done)
	go func() {
		select {
		case <-ctx.Done():
			_ = connection.Close()
		case <-done:
		}
	}()
	var output bytes.Buffer
	count := 0
	finish := func(truncated bool, reason string) (string, bool, string, error) {
		if errors.Is(ctx.Err(), context.Canceled) {
			return "", false, "", errors.New("bounded logs canceled")
		}
		data := output.Bytes()
		if reason == "byte_limit" {
			for removed := 0; removed < 3 && len(data) > 0 && !utf8.Valid(data); removed++ {
				data = data[:len(data)-1]
			}
		}
		if !utf8.Valid(data) {
			return "", false, "", errors.New("bounded logs encoding")
		}
		return string(data), truncated, reason, nil
	}
	readFailure := func(err error) (string, bool, string, error) {
		if errors.Is(ctx.Err(), context.Canceled) {
			return "", false, "", errors.New("bounded logs canceled")
		}
		if ctx.Err() == context.DeadlineExceeded {
			return finish(true, "deadline")
		}
		if deadline, ok := ctx.Deadline(); ok && !time.Now().Before(deadline) {
			return finish(true, "deadline")
		}
		if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
			return finish(false, "eof")
		}
		return "", false, "", errors.New("bounded logs stream unavailable")
	}
	var buffer [4096]byte
	for {
		kind, reader, err := connection.NextReader()
		if err != nil {
			return readFailure(err)
		}
		if kind != websocket.TextMessage && kind != websocket.BinaryMessage {
			return "", false, "", errors.New("bounded logs framing")
		}
		var prefix [3]byte
		if _, err = io.ReadFull(reader, prefix[:]); err != nil {
			if err == io.EOF || err == io.ErrUnexpectedEOF {
				return "", false, "", errors.New("bounded logs framing")
			}
			return readFailure(err)
		}
		if prefix[0] != '0' || prefix[1] < '0' || prefix[1] > '2' || prefix[2] != ' ' {
			return "", false, "", errors.New("bounded logs framing")
		}
		for {
			remaining := boundedLogBytes - output.Len()
			if remaining == 0 {
				return finish(true, "byte_limit")
			}
			size := len(buffer)
			if remaining < size {
				size = remaining
			}
			n, err := reader.Read(buffer[:size])
			if err != nil && err != io.EOF {
				return readFailure(err)
			}
			for _, value := range buffer[:n] {
				_ = output.WriteByte(value)
				if value == '\n' {
					count++
					if count == lines {
						return finish(true, "line_limit")
					}
				}
			}
			if output.Len() == boundedLogBytes {
				return finish(true, "byte_limit")
			}
			if err == io.EOF {
				break
			}
		}
	}
}

func executeContainerLogs(ctx context.Context, input *containerLogTicket, dialAddress string) (*containerLogResult, error) {
	if input.consume(time.Now()) != nil {
		return nil, errors.New("bounded logs ticket denied")
	}
	// Operator-owned private loopback address only; no part of the ticket supplies a URL or path.
	if dialAddress != "http://127.0.0.1:8080" {
		return nil, errors.New("bounded logs topology unavailable")
	}
	deadline := time.UnixMilli(input.Expires).Add(-100 * time.Millisecond)
	ctx, cancel := context.WithDeadline(ctx, deadline)
	defer cancel()
	target := url.URL{Scheme: "ws", Host: "127.0.0.1:8080", Path: "/v1/logs/"}
	target.RawQuery = url.Values{"token": []string{input.Token}}.Encode()
	dialer := websocket.Dialer{HandshakeTimeout: 5 * time.Second, Proxy: nil}
	connection, response, err := dialer.DialContext(ctx, target.String(), http.Header{})
	if response != nil && response.Body != nil {
		_ = response.Body.Close()
	}
	if err != nil {
		return nil, errors.New("bounded logs stream unavailable")
	}
	text, truncated, reason, err := collectContainerLogs(ctx, connection, input.Lines)
	if err != nil {
		return nil, err
	}
	return &containerLogResult{input.RequestID, input.ActorID, input.ProjectID, input.ContainerUUID, "logs", input.Lines, text, truncated, "unknown", reason}, nil
}

func runContainerLogsCLI(stdin io.Reader, stdout io.Writer) int {
	var input *containerLogTicket
	decoder := json.NewDecoder(io.LimitReader(stdin, 65537))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&input) != nil || decoder.Decode(&struct{}{}) != io.EOF {
		return 2
	}
	result, err := executeContainerLogs(context.Background(), input, "http://127.0.0.1:8080")
	if err != nil {
		return 2
	}
	if json.NewEncoder(stdout).Encode(result) != nil {
		return 2
	}
	return 0
}

func boundedLogsCLI() bool {
	if len(os.Args) == 2 && os.Args[1] == "--ai-container-logs" {
		os.Exit(runContainerLogsCLI(os.Stdin, os.Stdout))
		return true
	}
	return false
}
