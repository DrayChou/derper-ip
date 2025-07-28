# Build stage
FROM golang:1.23-alpine AS builder

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Install derper
RUN go install tailscale.com/cmd/derper@latest

# Runtime stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -S derper && adduser -S derper -G derper

# Create directories
RUN mkdir -p /var/lib/derper && chown derper:derper /var/lib/derper

# Copy the derper binary from builder stage
COPY --from=builder /go/bin/derper /usr/local/bin/derper

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Switch to non-root user
USER derper

# Set working directory
WORKDIR /var/lib/derper

# Expose ports
EXPOSE 9003/tcp 9004/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9003/ || exit 1

# Start derper
CMD ["/usr/local/bin/start.sh"]