package main

import (
	"flag"
	"log/slog"
	"net/http"
	"os"
	"time"
	"trust-wallet-assignment/handlers"
	"trust-wallet-assignment/middleware"
)

const (
	defaultUpstream = "https://polygon.drpc.org"
	defaultAddr     = ":8585"
)

var (
	upstream = flag.String("upstream", defaultUpstream, "Upstream RPC URL")
	addr     = flag.String("addr", defaultAddr, "Listen address")
	timeout  = flag.Duration("timeout", 30*time.Second, "Upstream request timeout")
)

func main() {
	flag.Parse()

	// Configure logger globally
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})))

	// Configure proxy routes
	client := &http.Client{Timeout: *timeout}
	proxy := &handlers.RPCProxy{Upstream: *upstream, Client: client}

	mux := http.NewServeMux()
	mux.HandleFunc("/", proxy.Handle)
	mux.HandleFunc("/health", handlers.Health)

	// Instantiate the proxy server
	srv := &http.Server{
		Addr:         *addr,
		Handler:      middleware.Logging(middleware.Metrics(mux)),
		ReadTimeout:  *timeout,
		WriteTimeout: *timeout + 5*time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Start the proxy server
	slog.Info("starting proxy", "addr", *addr, "upstream", *upstream)
	if err := srv.ListenAndServe(); err != nil {
		slog.Error("server error", "err", err)
		os.Exit(1)
	}
}
