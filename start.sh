#!/bin/sh

# Set default values if environment variables are not set
DERP_HOSTNAME=${DERP_HOSTNAME:-localhost}
DERP_HTTP_PORT=${DERP_HTTP_PORT:-9003}
DERP_STUN_PORT=${DERP_STUN_PORT:-9004}
DERP_VERIFY_CLIENTS=${DERP_VERIFY_CLIENTS:-false}
DERP_CERT_MODE=${DERP_CERT_MODE:-manual}
DERP_CERT_DIR=${DERP_CERT_DIR:-/var/lib/derper}
DERP_LOG_LEVEL=${DERP_LOG_LEVEL:-info}

# Create necessary directories
mkdir -p /var/log/derper
mkdir -p $DERP_CERT_DIR

# Print configuration
echo "Starting DERP server with configuration:"
echo "  Hostname: $DERP_HOSTNAME"
echo "  HTTP Port: $DERP_HTTP_PORT"
echo "  STUN Port: $DERP_STUN_PORT"
echo "  Verify Clients: $DERP_VERIFY_CLIENTS"
echo "  Cert Mode: $DERP_CERT_MODE"
echo "  Cert Directory: $DERP_CERT_DIR"
echo "  Log Level: $DERP_LOG_LEVEL"

# Create derper configuration file
cat > /tmp/derper.json << EOF
{
  "Hostname": "$DERP_HOSTNAME",
  "CertMode": "$DERP_CERT_MODE",
  "CertDir": "$DERP_CERT_DIR",
  "Addr": ":$DERP_HTTP_PORT",
  "HTTPPort": -1,
  "STUNPort": $DERP_STUN_PORT,
  "VerifyClients": $DERP_VERIFY_CLIENTS
}
EOF

echo "Created configuration file /tmp/derper.json:"
cat /tmp/derper.json

# Start derper with config file
echo "Starting derper with config file..."
exec /usr/local/bin/derper -c /tmp/derper.json