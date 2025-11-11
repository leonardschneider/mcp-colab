#!/bin/bash
# Troubleshooting script for Cloudflare tunnel issues

echo "========================================="
echo "Cloudflare Tunnel Troubleshooting"
echo "========================================="
echo ""

# Check if cloudflared is running
echo "[1/6] Checking if cloudflared is running..."
if pgrep -f "cloudflared tunnel" > /dev/null; then
    echo "✓ cloudflared process is running"
    echo "  PID: $(pgrep -f 'cloudflared tunnel')"
else
    echo "✗ cloudflared is NOT running"
    echo "  Try: ./start_cloudflare_tunnel.sh"
    exit 1
fi

echo ""

# Check if Jupyter is accessible locally
echo "[2/6] Checking local Jupyter Server..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/api | grep -q "200"; then
    echo "✓ Jupyter Server responds on localhost:8888"
else
    echo "✗ Jupyter Server NOT accessible on localhost:8888"
    echo "  Try: ./start_jupyter_server.sh"
    exit 1
fi

echo ""

# Check tunnel logs for errors
echo "[3/6] Recent tunnel logs (last 20 lines):"
echo "----------------------------------------"
if [ -f /tmp/cloudflared.log ]; then
    tail -20 /tmp/cloudflared.log
else
    echo "✗ No log file found at /tmp/cloudflared.log"
fi

echo ""
echo "----------------------------------------"
echo ""

# Check tunnel configuration
echo "[4/6] Checking tunnel configuration..."
if [ -f /content/cloudflare-tunnel.yml ]; then
    echo "✓ Config file exists"
    echo ""
    echo "Config contents:"
    cat /content/cloudflare-tunnel.yml
else
    echo "✗ Config file NOT found at /content/cloudflare-tunnel.yml"
    exit 1
fi

echo ""

# Check credentials
echo "[5/6] Checking tunnel credentials..."
if ls /content/tunnel-credentials/*.json > /dev/null 2>&1; then
    echo "✓ Credentials file found:"
    ls -lh /content/tunnel-credentials/*.json
else
    echo "✗ No credentials found in /content/tunnel-credentials/"
    echo "  Did you run 'cloudflared tunnel create'?"
    exit 1
fi

echo ""

# Check for common issues in logs
echo "[6/6] Analyzing logs for common issues..."
if [ -f /tmp/cloudflared.log ]; then
    if grep -q "error" /tmp/cloudflared.log; then
        echo "⚠️  Found errors in logs:"
        grep -i "error" /tmp/cloudflared.log | tail -5
    fi

    if grep -q "unable to reach" /tmp/cloudflared.log; then
        echo "⚠️  Tunnel cannot reach origin:"
        grep "unable to reach" /tmp/cloudflared.log | tail -3
    fi

    if grep -q "connection established" /tmp/cloudflared.log; then
        echo "✓ Tunnel connection was established"
    else
        echo "⚠️  No 'connection established' message in logs"
        echo "   Tunnel may still be connecting..."
    fi
fi

echo ""
echo "========================================="
echo "Troubleshooting Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Check the logs above for specific errors"
echo "2. Verify DNS is configured: colab.leonard-schneider.com"
echo "3. Wait 2-3 minutes for tunnel to fully establish"
echo "4. Try restarting the tunnel: pkill cloudflared && ./start_cloudflare_tunnel.sh"
echo ""
