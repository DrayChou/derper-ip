# Use Go 1.24 as the base image
FROM golang:1.24-alpine AS builder

# Install ca-certificates
RUN apk add --no-cache ca-certificates

# Install specific stable version to avoid build issues
RUN go install tailscale.com/cmd/derper@v1.82.1

# Create a minimal runtime image
FROM alpine:latest

# Install ca-certificates and openssl for certificate generation
RUN apk --no-cache add ca-certificates openssl

# Create a non-root user
RUN addgroup -g 1000 derp && \
    adduser -D -s /bin/sh -u 1000 -G derp derp

# Create necessary directories
RUN mkdir -p /var/lib/derper && \
    chown -R derp:derp /var/lib/derper

# Copy the derper binary from builder stage (from GOPATH)
COPY --from=builder /go/bin/derper /usr/local/bin/derper

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Switch to non-root user
USER derp

# Expose the default DERP port
EXPOSE 443
EXPOSE 80

# Set the startup script as entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]