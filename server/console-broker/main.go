package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

func main() {
	cfg, err := configFromEnvironment()
	if err != nil {
		log.Fatalf("invalid console broker configuration: %v", err)
	}

	logger := log.New(os.Stderr, "console-broker: ", log.LstdFlags|log.LUTC)
	broker, err := newBroker(cfg, logger)
	if err != nil {
		logger.Fatalf("initialization failed: %v", err)
	}
	defer broker.close()

	httpServer := &http.Server{
		Addr:              cfg.ListenAddress,
		Handler:           broker,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       90 * time.Second,
		MaxHeaderBytes:    1 << 20,
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-signals
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		if err := httpServer.Shutdown(ctx); err != nil {
			logger.Printf("graceful shutdown failed: %v", err)
		}
	}()

	logger.Printf("listening on %s and forwarding application traffic to %s", cfg.ListenAddress, cfg.UpstreamURL)
	if err := httpServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		logger.Fatalf("server failed: %v", err)
	}
}

func configFromEnvironment() (brokerConfig, error) {
	cfg := brokerConfig{
		ListenAddress: environmentString("PASTURESTACK_CONSOLE_LISTEN_ADDRESS", ":8081"),
		UpstreamURL:   environmentString("PASTURESTACK_CONSOLE_UPSTREAM_URL", "http://127.0.0.1:8082"),
		SessionDialURL: environmentString(
			"PASTURESTACK_CONSOLE_SESSION_DIAL_URL",
			"http://127.0.0.1:8080",
		),
		MaxSessions: environmentInt("PASTURESTACK_CONSOLE_MAX_SESSIONS", 24),
		ReplayBytes: environmentInt("PASTURESTACK_CONSOLE_REPLAY_BYTES", 2*1024*1024),
		ActiveTTL:   environmentDuration("PASTURESTACK_CONSOLE_ACTIVE_TTL", 72*time.Hour),
		HistoryTTL:  environmentDuration("PASTURESTACK_CONSOLE_HISTORY_TTL", 24*time.Hour),
		CleanupInterval: environmentDuration(
			"PASTURESTACK_CONSOLE_CLEANUP_INTERVAL",
			time.Minute,
		),
	}

	if cfg.MaxSessions < 1 || cfg.MaxSessions > 256 {
		return brokerConfig{}, errors.New("PASTURESTACK_CONSOLE_MAX_SESSIONS must be between 1 and 256")
	}
	if cfg.ReplayBytes < 64*1024 || cfg.ReplayBytes > 16*1024*1024 {
		return brokerConfig{}, errors.New("PASTURESTACK_CONSOLE_REPLAY_BYTES must be between 64 KiB and 16 MiB")
	}
	if cfg.ActiveTTL < time.Minute || cfg.HistoryTTL < time.Minute || cfg.CleanupInterval < time.Second {
		return brokerConfig{}, errors.New("session time limits are below their safe minimum")
	}

	return cfg, nil
}

func environmentString(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func environmentInt(name string, fallback int) int {
	value := os.Getenv(name)
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func environmentDuration(name string, fallback time.Duration) time.Duration {
	value := os.Getenv(name)
	if value == "" {
		return fallback
	}
	parsed, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}
	return parsed
}
