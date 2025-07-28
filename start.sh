#!/bin/sh

# Set default values - use IP mode by default
DERP_HOSTNAME=${DERP_HOSTNAME:-localhost}
DERP_HTTP_PORT=${DERP_HTTP_PORT:-9003}
DERP_STUN_PORT=${DERP_STUN_PORT:-9004}
DERP_VERIFY_CLIENTS=${DERP_VERIFY_CLIENTS:-true}

# Create certificate directory
CERT_DIR="/var/lib/derper"
mkdir -p $CERT_DIR

# Print configuration
echo "Starting DERP server with configuration:"
echo "  Hostname: $DERP_HOSTNAME"
echo "  HTTP Port: $DERP_HTTP_PORT"
echo "  STUN Port: $DERP_STUN_PORT"
echo "  Verify Clients: $DERP_VERIFY_CLIENTS"
echo "  Certificate Directory: $CERT_DIR"

# Debug information
echo ""
echo "=== Debug Info ==="
/usr/local/bin/derper --version 2>&1 || echo "No version info"
echo ""

# Change to certificate directory
cd $CERT_DIR

# Use exact same command as your production server (without config file)
echo "Starting derper with production-like command..."

# Build command exactly like production
DERPER_CMD="/usr/local/bin/derper --hostname=$DERP_HOSTNAME -certmode manual -certdir ./ -http-port -1 -a :$DERP_HTTP_PORT -stun-port $DERP_STUN_PORT"

# Add verify-clients if enabled
if [ "$DERP_VERIFY_CLIENTS" = "true" ]; then
    DERPER_CMD="$DERPER_CMD -verify-clients"
fi

echo "Command: $DERPER_CMD"
exec $DERPER_CMD