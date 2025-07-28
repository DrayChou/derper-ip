# Use Go 1.24 as the base image
FROM golang:1.24-alpine AS builder

# Set working directory
WORKDIR /app

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates

# Clone Tailscale repository
RUN git clone https://github.com/tailscale/tailscale.git .

# Build the derper binary
RUN go build -o derper ./cmd/derper

# Create a minimal runtime image
FROM alpine:latest

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Create a non-root user
RUN addgroup -g 1000 derp && \
    adduser -D -s /bin/sh -u 1000 -G derp derp

# Create necessary directories
RUN mkdir -p /var/lib/derper && \
    chown -R derp:derp /var/lib/derper

# Copy the derper binary from builder stage
COPY --from=builder /app/derper /usr/local/bin/derper

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