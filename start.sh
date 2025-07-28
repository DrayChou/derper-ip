#!/bin/sh

# Set default values if environment variables are not set
DERP_HOSTNAME=${DERP_HOSTNAME:-localhost}
DERP_HTTP_PORT=${DERP_HTTP_PORT:-9003}
DERP_STUN_PORT=${DERP_STUN_PORT:-9004}
DERP_VERIFY_CLIENTS=${DERP_VERIFY_CLIENTS:-false}
DERP_CERT_MODE=${DERP_CERT_MODE:-manual}
DERP_CERT_DIR=${DERP_CERT_DIR:-/var/lib/derper}
DERP_LOG_LEVEL=${DERP_LOG_LEVEL:-info}

# Create log directory
mkdir -p /var/log/derper

# Print configuration
echo "Starting DERP server with configuration:"
echo "  Hostname: $DERP_HOSTNAME"
echo "  HTTP Port: $DERP_HTTP_PORT"
echo "  STUN Port: $DERP_STUN_PORT"
echo "  Verify Clients: $DERP_VERIFY_CLIENTS"
echo "  Cert Mode: $DERP_CERT_MODE"
echo "  Cert Directory: $DERP_CERT_DIR"
echo "  Log Level: $DERP_LOG_LEVEL"

# Build the derper command
DERPER_CMD="/usr/local/bin/derper"
DERPER_CMD="$DERPER_CMD --hostname=$DERP_HOSTNAME"
DERPER_CMD="$DERPER_CMD --certmode=$DERP_CERT_MODE"
DERPER_CMD="$DERPER_CMD --certdir=$DERP_CERT_DIR"
DERPER_CMD="$DERPER_CMD --http-port=-1"
DERPER_CMD="$DERPER_CMD --a=:$DERP_HTTP_PORT"
DERPER_CMD="$DERPER_CMD --stun-port=$DERP_STUN_PORT"

# Add verify-clients flag if enabled
if [ "$DERP_VERIFY_CLIENTS" = "true" ]; then
    DERPER_CMD="$DERPER_CMD --verify-clients"
fi

# Add verbose logging if debug level
if [ "$DERP_LOG_LEVEL" = "debug" ]; then
    DERPER_CMD="$DERPER_CMD --v=2"
fi

echo "Executing: $DERPER_CMD"

# Start derper with exec to ensure proper signal handling
exec $DERPER_CMD