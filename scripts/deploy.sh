#!/bin/bash

# Automated DERP Server Deployment Script
# Usage: ./deploy.sh <server_ip> [http_port] [stun_port]

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <server_ip> [http_port] [stun_port]"
    echo "Example: $0 88.88.88.88 9003 9004"
    exit 1
fi

SERVER_IP=$1
HTTP_PORT=${2:-9003}
STUN_PORT=${3:-9004}

echo "=== Tailscale DERP Server Deployment ==="
echo "Server IP: $SERVER_IP"
echo "HTTP Port: $HTTP_PORT"
echo "STUN Port: $STUN_PORT"
echo "========================================"

# Detect binary
BINARY_NAME=""
for file in derper-* derper; do
    if [ -x "$file" ] 2>/dev/null; then
        BINARY_NAME="$file"
        break
    fi
done

if [ -z "$BINARY_NAME" ]; then
    echo "Error: No derper binary found"
    exit 1
fi

echo "Using binary: $BINARY_NAME"

# Create directories
mkdir -p certs logs

# Check if running as root (for systemd service)
if [ "$(id -u)" = "0" ]; then
    echo "Running as root - can create systemd service"
    CREATE_SERVICE=true
else
    echo "Running as user - will start in foreground"
    CREATE_SERVICE=false
fi

# Create systemd service if running as root
if [ "$CREATE_SERVICE" = "true" ]; then
    cat > /etc/systemd/system/derper.service << EOF
[Unit]
Description=Tailscale DERP Server
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=$(pwd)/certs
ExecStart=$(pwd)/$BINARY_NAME --hostname="$SERVER_IP" -certmode manual -certdir ./ -http-port -1 -a :$HTTP_PORT -stun-port $STUN_PORT -verify-clients
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    echo "Created systemd service: /etc/systemd/system/derper.service"
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable derper
    systemctl start derper
    
    echo ""
    echo "✅ DERP server started as systemd service"
    echo ""
    echo "Service commands:"
    echo "  systemctl status derper   - Check status"
    echo "  systemctl logs derper     - View logs"
    echo "  systemctl restart derper  - Restart service"
    echo "  systemctl stop derper     - Stop service"
    
else
    # Start in foreground
    echo ""
    echo "Starting DERP server in foreground..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    cd certs
    exec ../$BINARY_NAME --hostname="$SERVER_IP" -certmode manual -certdir ./ -http-port -1 -a :$HTTP_PORT -stun-port $STUN_PORT -verify-clients
fi

echo ""
echo "🎉 DERP server deployment completed!"
echo ""
echo "Server details:"
echo "  IP: $SERVER_IP"
echo "  HTTP Port: $HTTP_PORT"
echo "  STUN Port: $STUN_PORT"
echo ""
echo "Firewall requirements:"
echo "  sudo ufw allow $HTTP_PORT/tcp"
echo "  sudo ufw allow $STUN_PORT/udp"
echo ""
echo "Add this to your Tailscale ACL:"
echo "Check the server logs for the DERP region configuration."