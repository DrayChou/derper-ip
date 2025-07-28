#!/bin/sh

# Tailscale DERP Server Startup Script
# This script configures and starts the Tailscale DERP server

set -e

# Default values
DERP_DOMAIN=${DERP_DOMAIN:-localhost}
DERP_CERTMODE=${DERP_CERTMODE:-manual}
DERP_CERTDIR=${DERP_CERTDIR:-/certs}
DERP_HOSTNAME=${DERP_HOSTNAME:-derp-server}
DERP_STUN=${DERP_STUN:-true}
DERP_STUN_PORT=${DERP_STUN_PORT:-3478}
DERP_LOGFILE=${DERP_LOGFILE:-/var/log/derper/derper.log}
DERP_VERBOSE=${DERP_VERBOSE:-false}
DERP_HTTP_PORT=${DERP_HTTP_PORT:-80}
DERP_HTTPS_PORT=${DERP_HTTPS_PORT:-443}
DERP_VERIFY_CLIENTS=${DERP_VERIFY_CLIENTS:-false}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$DERP_LOGFILE")"

echo "========================================="
echo "Starting Tailscale DERP Server"
echo "========================================="
echo "Domain: $DERP_DOMAIN"
echo "Cert Mode: $DERP_CERTMODE"
echo "Cert Directory: $DERP_CERTDIR"
echo "Hostname: $DERP_HOSTNAME"
echo "STUN Enabled: $DERP_STUN"
echo "STUN Port: $DERP_STUN_PORT"
echo "HTTP Port: $DERP_HTTP_PORT"
echo "HTTPS Port: $DERP_HTTPS_PORT"
echo "Log File: $DERP_LOGFILE"
echo "Verbose Logging: $DERP_VERBOSE"
echo "Verify Clients: $DERP_VERIFY_CLIENTS"
echo "========================================="

# Build the derper command arguments
DERP_ARGS=""

# Add hostname
DERP_ARGS="$DERP_ARGS -hostname=$DERP_HOSTNAME"

# Add HTTP port
DERP_ARGS="$DERP_ARGS -http-port=$DERP_HTTP_PORT"

# Add HTTPS port  
DERP_ARGS="$DERP_ARGS -a=:$DERP_HTTPS_PORT"

# Add certificate configuration
if [ "$DERP_CERTMODE" = "letsencrypt" ]; then
    DERP_ARGS="$DERP_ARGS -certmode=letsencrypt"
    DERP_ARGS="$DERP_ARGS -certdir=$DERP_CERTDIR"
elif [ "$DERP_CERTMODE" = "manual" ]; then
    DERP_ARGS="$DERP_ARGS -certmode=manual"
    DERP_ARGS="$DERP_ARGS -certdir=$DERP_CERTDIR"
else
    # Default to manual mode
    DERP_ARGS="$DERP_ARGS -certmode=manual"
    DERP_ARGS="$DERP_ARGS -certdir=$DERP_CERTDIR"
fi

# Add STUN configuration
if [ "$DERP_STUN" = "true" ]; then
    DERP_ARGS="$DERP_ARGS -stun-port=$DERP_STUN_PORT"
fi

# Add verbose logging if enabled
if [ "$DERP_VERBOSE" = "true" ]; then
    DERP_ARGS="$DERP_ARGS -v"
fi

# Add client verification if enabled
if [ "$DERP_VERIFY_CLIENTS" = "true" ]; then
    DERP_ARGS="$DERP_ARGS -verify-clients"
fi

# Add mesh configuration if provided
if [ -n "$DERP_MESH_WITH" ]; then
    DERP_ARGS="$DERP_ARGS -mesh-with=$DERP_MESH_WITH"
fi

# Add bootstrap DNS if provided
if [ -n "$DERP_BOOTSTRAP_DNS" ]; then
    DERP_ARGS="$DERP_ARGS -bootstrap-dns=$DERP_BOOTSTRAP_DNS"
fi

# Create a simple probe endpoint for health checks
cat > /tmp/probe.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>DERP Server Status</title>
</head>
<body>
    <h1>Tailscale DERP Server</h1>
    <p>Status: Running</p>
    <p>Server ready to accept connections</p>
</body>
</html>
EOF

echo "Starting DERP server with arguments: $DERP_ARGS"

# Log the startup
echo "$(date): Starting Tailscale DERP server" >> "$DERP_LOGFILE"

# Execute the derper with the constructed arguments
exec /usr/local/bin/derper $DERP_ARGS