package handlers

import (
	"bytes"
	"compress/gzip"
	"errors"
	"io"
	"log/slog"
	"net/http"
)

const maxRequestBody = 8 << 20 // 8 MiB — hard cap on incoming JSON-RPC bodies.

// RPC Proxy forwards JSON-RPC requests to the upstream endpoint.

type RPCProxy struct {
	Upstream string
	Client   *http.Client
}

func (p *RPCProxy) Handle(w http.ResponseWriter, request *http.Request) {
	// Only POST is valid for JSON-RPC.
	if request.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read the request body to be forwarded to upstream repository.
	request.Body = http.MaxBytesReader(w, request.Body, maxRequestBody)
	defer request.Body.Close()

	body, err := io.ReadAll(request.Body)
	if err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			slog.Warn("request body too large", "limit_bytes", maxErr.Limit)
			http.Error(w, "request body too large", http.StatusRequestEntityTooLarge)
			return
		}
		slog.Error("read body", "err", err)
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	upstreamRequest, err := http.NewRequestWithContext(request.Context(), http.MethodPost, p.Upstream, bytes.NewReader(body))
	if err != nil {
		slog.Error("build upstream request", "err", err, "upstream", p.Upstream)
		http.Error(w, "internal server error", http.StatusInternalServerError)
		return
	}

	// Copy original request header to the upstream request
	upstreamRequest.Header.Set("Content-Type", "application/json")
	for _, h := range []string{"Accept", "Accept-Encoding", "X-Request-Id"} {
		if v := request.Header.Get(h); v != "" {
			upstreamRequest.Header.Set(h, v)
		}
	}

	upstreamResponse, err := p.Client.Do(upstreamRequest)
	if err != nil {
		slog.Error("upstream request failed", "err", err, "upstream", p.Upstream)
		http.Error(w, "bad gateway", http.StatusBadGateway)
		return
	}
	defer upstreamResponse.Body.Close()

	// Copy headers and status from upstream response back to the current response
	for k, vs := range upstreamResponse.Header {
		// One key maps to multiple header value
		for _, v := range vs {
			w.Header().Add(k, v)
		}
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(upstreamResponse.StatusCode)

	// Write back to the client the upstream body.
	respBody, err := readBody(upstreamResponse)
	if err != nil {
		slog.Error("read upstream body", "err", err)
		return
	}

	// Write back to the client
	if _, err := w.Write(respBody); err != nil {
		slog.Error("write response", "err", err)
	}
}

// readBody handles optional gzip-encoded upstream responses.
func readBody(resp *http.Response) ([]byte, error) {
	if resp.Header.Get("Content-Encoding") == "gzip" {
		gr, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, err
		}
		defer gr.Close()
		return io.ReadAll(gr)
	}
	return io.ReadAll(resp.Body)
}
