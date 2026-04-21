package middleware

import (
	"log/slog"
	"net/http"
	"time"
)

// Metrics is a placeholder metrics middleware. It captures per-request
// info (method, path, status, latency) and emits them as a structured log.
func Metrics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)

		slog.Info("metric",
			"name", "http_request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", rec.status,
			"status_class", statusClass(rec.status),
			"latency_ms", time.Since(start).Milliseconds(),
		)
	})
}

// statusRecorder wraps http.ResponseWriter so the middleware can read back
// the status code the downstream handler wrote. Defaults to 200 because
// net/http implicitly sends 200 when a handler writes a body without first
// calling WriteHeader.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (sr *statusRecorder) WriteHeader(code int) {
	sr.status = code
	sr.ResponseWriter.WriteHeader(code)
}

// statusClass buckets an HTTP status into the standard class labels used
// by most metrics systems (e.g. Prometheus label `code`).
func statusClass(status int) string {
	switch {
	case status >= 500:
		return "5xx"
	case status >= 400:
		return "4xx"
	case status >= 300:
		return "3xx"
	case status >= 200:
		return "2xx"
	default:
		return "1xx"
	}
}
