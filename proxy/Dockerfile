# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy dependency files first — cached unless go.mod changes.
# No go.sum yet because the proxy only uses stdlib packages.
# If you add external deps, run `go mod tidy` and re-add `go.sum` to this COPY.
COPY go.mod ./
RUN go mod download

# Copy the full module source (main + subpackages like handlers/ and middleware/).
# `COPY . .` is intentional — `COPY *.go ./` only picks up files in the module
# root and silently drops subpackages, producing a "package not in std" build error.
COPY . .
# CGO_ENABLED=0 Pure-Go implementations for everything — no cgo calls, no C dependencies, no dynamic linking.
# The binary is fully static — all code is bundled into the single output file - this allows us to create final Docker image FROM scratch.
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o proxy .

# ─── Stage 2: Run ─────────────────────────────────────────────────────────────
FROM scratch

# Copy CA certificates so TLS calls to polygon.drpc.org work
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy passwd so the runtime knows about the non-root user
COPY --from=builder /etc/passwd /etc/passwd

COPY --from=builder /app/proxy /proxy

USER nobody

EXPOSE 8545

ENTRYPOINT ["/proxy"]