#!/bin/bash
# Start Cloudflare Tunnel in background

set -e

TUNNEL_CONFIG="/content/cloudflare-tunnel.yml"

if [ ! -f "$TUNNEL_CONFIG" ]; then
    echo "Error: Tunnel configuration not found at $TUNNEL_CONFIG"
    echo ""
    echo "Please create the tunnel configuration first:"
    echo "  1. Run: cloudflared tunnel login"
    echo "  2. Create tunnel: cloudflared tunnel create colab-tunnel"
    echo "  3. Create config file (see documentation)"
    echo ""
    exit 1
fi

echo "Starting Cloudflare Tunnel..."

# Kill any existing cloudflared process
pkill -f "cloudflared tunnel" || true

# Start tunnel in background
nohup cloudflared tunnel --config "$TUNNEL_CONFIG" run \
    > /tmp/cloudflared.log 2>&1 &

TUNNEL_PID=$!

echo "Cloudflare Tunnel started with PID: $TUNNEL_PID"
echo "Logs: /tmp/cloudflared.log"
echo ""
echo "To view logs: tail -f /tmp/cloudflared.log"
echo "To stop: kill $TUNNEL_PID"
echo ""

# Wait and check if tunnel is running
sleep 5

if ps -p $TUNNEL_PID > /dev/null; then
    echo "✓ Cloudflare Tunnel is running"
    echo "  Remote access: https://colab.leonard-schneider.com"
else
    echo "✗ Cloudflare Tunnel failed to start"
    echo "  Check logs at /tmp/cloudflared.log"
    exit 1
fi
