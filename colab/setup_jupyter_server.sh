#!/bin/bash
# Colab Jupyter Server Setup Script
# This script sets up a Jupyter server in Google Colab that can be accessed remotely
# via Cloudflare tunnel for use with MCP Server and JupyterLab

set -e

echo "========================================="
echo "Google Colab Jupyter Server Setup"
echo "========================================="
echo ""

# Install Jupyter Server and required extensions
echo "[1/5] Installing Jupyter Server and extensions..."
pip install -q jupyter-server jupyterlab jupyter_http_over_ws jupyter-collaboration

# Enable the HTTP over WebSocket extension
echo "[2/5] Enabling jupyter_http_over_ws extension..."
jupyter serverextension enable --py jupyter_http_over_ws

# Generate Jupyter config if it doesn't exist
echo "[3/5] Configuring Jupyter Server..."
mkdir -p ~/.jupyter

# Create Jupyter server configuration
cat > ~/.jupyter/jupyter_server_config.py << 'EOF'
# Jupyter Server Configuration for Remote Access

c = get_config()

# Allow connections from any origin (needed for Cloudflare tunnel)
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True

# Disable token authentication (Cloudflare tunnel handles security)
# WARNING: Only use this behind Cloudflare Access or similar authentication!
c.ServerApp.token = ''
c.ServerApp.password = ''

# Allow remote access
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.open_browser = False

# Enable collaboration features
c.ServerApp.jpserver_extensions = {
    'jupyter_server_collaboration': True
}

# Port configuration
c.ServerApp.port = 8888
c.ServerApp.port_retries = 0

# Root directory (Colab's default)
c.ServerApp.root_dir = '/content'

# Disable XSRF checks for WebSocket (needed for remote access)
c.ServerApp.disable_check_xsrf = True

# Trust all notebooks (since we're the only user)
c.ServerApp.trust_xheaders = True
EOF

echo "Configuration created at ~/.jupyter/jupyter_server_config.py"

# Install Cloudflare tunnel (cloudflared)
echo "[4/5] Installing cloudflared..."
if [ ! -f /usr/local/bin/cloudflared ]; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    chmod +x cloudflared-linux-amd64
    sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
    echo "cloudflared installed successfully"
else
    echo "cloudflared already installed"
fi

# Check if tunnel credentials exist
echo "[5/5] Checking Cloudflare tunnel configuration..."
TUNNEL_CREDS_DIR="/content/tunnel-credentials"
TUNNEL_CONFIG_FILE="/content/cloudflare-tunnel.yml"

if [ ! -d "$TUNNEL_CREDS_DIR" ] || [ ! -f "$TUNNEL_CONFIG_FILE" ]; then
    echo ""
    echo "⚠️  Cloudflare tunnel not configured yet!"
    echo ""
    echo "To complete setup:"
    echo "1. Create a tunnel: cloudflared tunnel create colab-tunnel"
    echo "2. Save credentials to: $TUNNEL_CREDS_DIR/"
    echo "3. Create config at: $TUNNEL_CONFIG_FILE"
    echo "4. Configure DNS for colab.leonard-schneider.com"
    echo ""
    echo "See setup documentation for detailed instructions."
else
    echo "✓ Tunnel credentials found"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Start Jupyter Server: ./start_jupyter_server.sh"
echo "2. Start Cloudflare tunnel: ./start_cloudflare_tunnel.sh"
echo "3. Connect JupyterLab to: https://colab.leonard-schneider.com"
echo ""
