#!/bin/bash
# Quick diagnosis script for 530 errors

echo "=== Quick 530 Error Diagnosis ==="
echo ""

# 1. Check if Jupyter is actually listening
echo "[1] Testing Jupyter Server locally..."
JUPYTER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/api)
echo "Jupyter API status: $JUPYTER_STATUS"

if [ "$JUPYTER_STATUS" != "200" ]; then
    echo "❌ PROBLEM: Jupyter is not responding properly"
    echo "   Expected: 200, Got: $JUPYTER_STATUS"
    echo ""
    echo "Try restarting Jupyter:"
    echo "  pkill -f jupyter-lab"
    echo "  ./start_jupyter_server.sh"
    exit 1
fi
echo "✓ Jupyter is working locally"
echo ""

# 2. Check tunnel process
echo "[2] Checking cloudflared process..."
if pgrep -f "cloudflared tunnel run" > /dev/null; then
    echo "✓ cloudflared is running (PID: $(pgrep -f 'cloudflared tunnel run'))"
else
    echo "❌ PROBLEM: cloudflared is NOT running"
    echo ""
    echo "Start it with:"
    echo "  ./start_cloudflare_tunnel.sh"
    exit 1
fi
echo ""

# 3. Check config file
echo "[3] Checking tunnel configuration..."
if [ ! -f /content/cloudflare-tunnel.yml ]; then
    echo "❌ PROBLEM: Config file not found!"
    exit 1
fi

echo "Current config:"
echo "---"
cat /content/cloudflare-tunnel.yml
echo "---"
echo ""

# Check for common config issues
if grep -q "service: https://localhost:8888" /content/cloudflare-tunnel.yml; then
    echo "❌ PROBLEM FOUND: Using https:// instead of http://"
    echo "   The service URL should be: http://localhost:8888"
    echo "   NOT: https://localhost:8888"
    echo ""
    echo "Fix it with:"
    echo "  sed -i 's|https://localhost:8888|http://localhost:8888|g' /content/cloudflare-tunnel.yml"
    echo "  pkill cloudflared"
    echo "  ./start_cloudflare_tunnel.sh"
fi

if ! grep -q "noTLSVerify: true" /content/cloudflare-tunnel.yml; then
    echo "⚠️  WARNING: noTLSVerify not set"
    echo "   Add under originRequest:"
    echo "     originRequest:"
    echo "       noTLSVerify: true"
fi

echo ""

# 4. Test with curl through the tunnel
echo "[4] Testing external access..."
TUNNEL_URL="https://colab.leonard-schneider.com/api"
echo "Testing: $TUNNEL_URL"

TUNNEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TUNNEL_URL" 2>&1)
echo "Tunnel status: $TUNNEL_STATUS"

if [ "$TUNNEL_STATUS" = "530" ]; then
    echo "❌ CONFIRMED: 530 error"
    echo ""
    echo "This means Cloudflare cannot reach your Jupyter server."
    echo ""
    echo "Most common causes:"
    echo "  1. Config has wrong service URL (use http:// not https://)"
    echo "  2. Tunnel credentials/ID mismatch"
    echo "  3. Tunnel still starting (wait 30 seconds)"
    echo ""
fi

echo ""

# 5. Show actual tunnel logs
echo "[5] Last 30 lines of tunnel logs:"
echo "================================="
if [ -f /tmp/cloudflared.log ]; then
    tail -30 /tmp/cloudflared.log | grep -v "^$"
else
    echo "No log file at /tmp/cloudflared.log"
    echo ""
    echo "Check where cloudflared is logging:"
    echo "  ps aux | grep cloudflared"
fi
echo "================================="
echo ""

# 6. Summary
echo "=== SUMMARY ==="
echo ""
echo "If you see 'ERR' or 'error' in the logs above, that's your issue."
echo ""
echo "Common fixes:"
echo "1. Wrong service URL → Edit config, change https to http"
echo "2. Can't reach origin → Check Jupyter is on port 8888"
echo "3. Authentication error → Verify tunnel ID matches credentials file"
echo ""
