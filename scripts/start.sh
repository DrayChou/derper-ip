#!/bin/bash

# Tailscale DERP Server Startup Script
# Usage: ./start.sh [hostname] [http_port] [stun_port]

set -e

# Default configuration
DERP_HOSTNAME=${1:-${DERP_HOSTNAME:-localhost}}
DERP_HTTP_PORT=${2:-${DERP_HTTP_PORT:-9003}}
DERP_STUN_PORT=${3:-${DERP_STUN_PORT:-9004}}
DERP_VERIFY_CLIENTS=${DERP_VERIFY_CLIENTS:-true}

# Detect binary name
BINARY_NAME=""
for file in derper-* derper; do
    if [ -x "$file" ] 2>/dev/null; then
        BINARY_NAME="$file"
        break
    fi
done

if [ -z "$BINARY_NAME" ]; then
    echo "Error: No derper binary found in current directory"
    echo "Please ensure you have extracted the archive and are in the correct directory"
    exit 1
fi

# Create necessary directories
mkdir -p certs logs

echo "=== Tailscale DERP Server Startup ==="
echo "Binary: $BINARY_NAME"
echo "Hostname: $DERP_HOSTNAME"
echo "HTTP Port: $DERP_HTTP_PORT"
echo "STUN Port: $DERP_STUN_PORT"
echo "Verify Clients: $DERP_VERIFY_CLIENTS"
echo "Working Directory: $(pwd)"
echo "=================================="

# Build command
CMD="./$BINARY_NAME --hostname=\"$DERP_HOSTNAME\" -certmode manual -certdir ./certs -http-port -1 -a :$DERP_HTTP_PORT -stun-port $DERP_STUN_PORT"

if [ "$DERP_VERIFY_CLIENTS" = "true" ]; then
    CMD="$CMD -verify-clients"
fi

echo "Executing: $CMD"
echo ""

# Change to certs directory for certificate generation
cd certs

# Execute the command
exec ../$BINARY_NAME --hostname="$DERP_HOSTNAME" -certmode manual -certdir ./ -http-port -1 -a :$DERP_HTTP_PORT -stun-port $DERP_STUN_PORT $([ "$DERP_VERIFY_CLIENTS" = "true" ] && echo "-verify-clients")