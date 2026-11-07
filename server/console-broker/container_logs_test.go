package main

import (
	"bytes"
	"context"
	"encoding/json"
	"github.com/gorilla/websocket"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"
	"unicode/utf8"
)

func logTicket() *containerLogTicket {
	return &containerLogTicket{RequestID: "ailogs-11111111-1111-1111-1111-111111111111", ActorID: 42, ProjectID: 5, ContainerUUID: "22222222-2222-2222-2222-222222222222", Operation: "logs", Expires: time.Now().Add(4 * time.Second).UnixMilli(), Lines: 200, Token: "PRIVATE_NATIVE_TOKEN"}
}
func logsConnection(t *testing.T, write func(*websocket.Conn)) *websocket.Conn {
	t.Helper()
	up := websocket.Upgrader{}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		connection, err := up.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		defer connection.Close()
		write(connection)
	}))
	t.Cleanup(server.Close)
	connection, response, err := websocket.DefaultDialer.Dial("ws"+strings.TrimPrefix(server.URL, "http"), nil)
	if response != nil && response.Body != nil {
		_ = response.Body.Close()
	}
	if err != nil {
		t.Fatal("local fixture dial failed")
	}
	return connection
}
func eof(c *websocket.Conn) {
	_ = c.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
}
func TestBoundedLogsTicketRejectsReplayInvalidScopeAndLifetime(t *testing.T) {
	input := logTicket()
	if input.consume(time.Now()) != nil || input.consume(time.Now()) == nil {
		t.Fatal("ticket replay")
	}
	for _, change := range []func(*containerLogTicket){func(v *containerLogTicket) { v.Operation = "exec" }, func(v *containerLogTicket) { v.ActorID = 0 }, func(v *containerLogTicket) { v.ProjectID = 0 }, func(v *containerLogTicket) { v.ContainerUUID = "raw-id" }, func(v *containerLogTicket) { v.Expires = 1 }, func(v *containerLogTicket) { v.Expires = time.Now().Add(6 * time.Second).UnixMilli() }, func(v *containerLogTicket) { v.Lines = 201 }, func(v *containerLogTicket) { v.Token = "" }} {
		input := logTicket()
		change(input)
		if input.consume(time.Now()) == nil {
			t.Fatal("invalid ticket allowed")
		}
		if input.consume(time.Now()) == nil {
			t.Fatal("failed ticket revived")
		}
	}
}
func TestBoundedLogsCLIRejectsUnknownURLAndMultipleRequestsWithoutOutput(t *testing.T) {
	for _, data := range []string{`null`, `{"url":"http://evil"}`, `{} {}`, `{"actorId":1.5}`, strings.Repeat("x", 65538)} {
		var output bytes.Buffer
		if runContainerLogsCLI(strings.NewReader(data), &output) == 0 || output.Len() != 0 {
			t.Fatal("private input rejection leaked output")
		}
	}
	input := logTicket()
	if _, err := executeContainerLogs(context.Background(), input, "http://foreign:8080"); err == nil {
		t.Fatal("arbitrary dial target accepted")
	}
}
func TestBoundedLogsNativeFramingAndEOFKeepUnknown(t *testing.T) {
	c := logsConnection(t, func(c *websocket.Conn) {
		_ = c.WriteMessage(websocket.TextMessage, []byte("01  first\n"))
		_ = c.WriteMessage(websocket.BinaryMessage, []byte("02 second[RANLOGS]\n"))
		_ = c.WriteMessage(websocket.TextMessage, []byte("00 third\n"))
		eof(c)
	})
	text, truncated, reason, err := collectContainerLogs(context.Background(), c, 200)
	if err != nil || text != " first\nsecond[RANLOGS]\nthird\n" || truncated || reason != "eof" {
		t.Fatal("valid native framing changed")
	}
}
func TestBoundedLogsLineLimitIsEnforcedIndependentlyOfAgent(t *testing.T) {
	c := logsConnection(t, func(c *websocket.Conn) {
		_ = c.WriteMessage(websocket.TextMessage, []byte("01 "+strings.Repeat("line\n", 201)))
		eof(c)
	})
	text, truncated, reason, err := collectContainerLogs(context.Background(), c, 200)
	if err != nil || strings.Count(text, "\n") != 200 || !truncated || reason != "line_limit" {
		t.Fatal("line bound")
	}
}
func TestBoundedLogsByteLimitAndUTF8Boundary(t *testing.T) {
	for _, test := range []struct {
		name    string
		padding int
		tail    string
		bytes   int
	}{
		{"partial-three-byte-rune", 65534, "中", 65534},
		{"partial-four-byte-rune", 65533, "😀", 65533},
		{"complete-four-byte-rune", 65532, "😀", 65536},
	} {
		t.Run(test.name, func(t *testing.T) {
			c := logsConnection(t, func(c *websocket.Conn) {
				_ = c.WriteMessage(websocket.BinaryMessage, []byte("01 "+strings.Repeat("a", test.padding)+test.tail))
				eof(c)
			})
			text, truncated, reason, err := collectContainerLogs(context.Background(), c, 200)
			if err != nil || len(text) > boundedLogBytes || len(text) != test.bytes || !utf8.ValidString(text) || !truncated || reason != "byte_limit" {
				t.Fatal("UTF8 byte bound")
			}
		})
	}
}

func TestBoundedLogsMalformedFrameAndEncodingFailWithoutContents(t *testing.T) {
	for _, frame := range [][]byte{[]byte("11 PRIVATE"), []byte("09 PRIVATE"), {}, {'0'}, {'0', '1'}, []byte("01xPRIVATE"), []byte("01\tPRIVATE"), {'0', '1', ' ', 0xff}} {
		c := logsConnection(t, func(c *websocket.Conn) { _ = c.WriteMessage(websocket.BinaryMessage, frame); eof(c) })
		text, _, _, err := collectContainerLogs(context.Background(), c, 200)
		if err == nil || text != "" {
			t.Fatal("malformed native output allowed")
		}
	}
}
func TestBoundedLogsDeadlineAndCancellationCloseReader(t *testing.T) {
	for _, cancelOnly := range []bool{false, true} {
		c := logsConnection(t, func(c *websocket.Conn) {
			_ = c.WriteMessage(websocket.TextMessage, []byte("01 prefix\n"))
			_, _, _ = c.ReadMessage()
		})
		ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
		if cancelOnly {
			go func() { time.Sleep(10 * time.Millisecond); cancel() }()
		}
		start := time.Now()
		text, truncated, reason, err := collectContainerLogs(ctx, c, 200)
		cancel()
		if time.Since(start) > 500*time.Millisecond {
			t.Fatal("reader cancellation failed")
		}
		if cancelOnly {
			if err == nil || text != "" {
				t.Fatal("canceled content escaped")
			}
		} else if err != nil || !truncated || reason != "deadline" {
			t.Fatal("deadline not explicit")
		}
	}
}
func TestBoundedLogsResultNeverIncludesTicket(t *testing.T) {
	result := containerLogResult{RequestID: "id", ActorID: 42, ProjectID: 5, ContainerUUID: "uuid", Operation: "logs", Lines: 100, Text: "data", Completeness: "unknown", StopReason: "eof"}
	b, err := json.Marshal(result)
	if err != nil || bytes.Contains(b, []byte("token")) || bytes.Contains(b, []byte("url")) {
		t.Fatal("ticket exposed")
	}
	var parsed map[string]any
	decoder := json.NewDecoder(bytes.NewReader(b))
	if decoder.Decode(&parsed) != nil || decoder.Decode(&struct{}{}) != io.EOF || parsed["completeness"] != "unknown" {
		t.Fatal("output contract")
	}
}

// A genuine native message can be larger than the public output budget. Keep
// its writer open so this also proves the reader stops without waiting for EOF.
func TestBoundedLogsNativeMessageStopsAtByteBudgetWithoutEOF(t *testing.T) {
	for _, size := range []int{boundedLogBytes, 1024 * 1024} {
		t.Run(strconv.Itoa(size), func(t *testing.T) {
			release := make(chan struct{})
			defer close(release)
			c := logsConnection(t, func(c *websocket.Conn) {
				writer, err := c.NextWriter(websocket.BinaryMessage)
				if err != nil {
					return
				}
				_, _ = writer.Write([]byte("01 " + strings.Repeat("x", size)))
				<-release
				_ = writer.Close()
			})
			ctx, cancel := context.WithTimeout(context.Background(), time.Second)
			defer cancel()
			text, truncated, reason, err := collectContainerLogs(ctx, c, 200)
			if err != nil || len(text) != boundedLogBytes || text != strings.Repeat("x", boundedLogBytes) || !truncated || reason != "byte_limit" {
				t.Fatal("native message did not stop at the payload byte budget")
			}
		})
	}
}

func TestBoundedLogsNativePrefixAcrossContinuationFrames(t *testing.T) {
	c := logsConnection(t, func(c *websocket.Conn) {
		// Server frames are unmasked. Split the three-byte native prefix
		// across continuation frames inside one logical WebSocket message.
		for _, frame := range [][]byte{
			{0x01, 1, '0'},
			{0x00, 1, '1'},
			{0x80, 7, ' ', 'c', 'h', 'u', 'n', 'k', '\n'},
		} {
			if _, err := c.UnderlyingConn().Write(frame); err != nil {
				return
			}
		}
		eof(c)
	})
	text, truncated, reason, err := collectContainerLogs(context.Background(), c, 200)
	if err != nil || text != "chunk\n" || truncated || reason != "eof" {
		t.Fatal("fragmented native prefix changed the application payload")
	}
}
