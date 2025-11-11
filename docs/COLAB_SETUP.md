# Google Colab Setup for Jupyter MCP Server

This guide walks you through setting up a Jupyter Server in Google Colab that can be accessed remotely by your local JupyterLab and MCP Server, enabling AI-assisted ML experiments on Colab's GPU/TPU hardware.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Overview

This setup allows you to:

- 🤖 Use Claude/Codex with Jupyter MCP Server for AI-assisted coding
- 🚀 Execute code on Google Colab's GPU/TPU hardware
- 👀 See changes in real-time as the AI agent works
- 🔄 Maintain your existing local JupyterLab + MCP Server setup
- 🌐 Access via your custom domain (`colab.leonard-schneider.com`)

## Architecture

```
┌─────────────────────────────────────┐
│     Your Local Machine              │
│                                     │
│  ┌──────────────┐                  │
│  │Claude Desktop│                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │  MCP Server  │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │  JupyterLab  │◄─────────┐      │
│  │  (Browser)   │          │      │
│  └──────────────┘          │      │
└─────────────────────────────┼──────┘
                              │
                    ┌─────────▼──────────┐
                    │ Cloudflare Tunnel  │
                    │ colab.leonard-     │
                    │ schneider.com      │
                    └─────────┬──────────┘
                              │
┌─────────────────────────────┼──────┐
│     Google Colab            │      │
│                             │      │
│  ┌──────────────────────────▼────┐│
│  │    Jupyter Server              ││
│  │    (port 8888)                 ││
│  └──────────────┬─────────────────┘│
│                 │                  │
│  ┌──────────────▼─────────────────┐│
│  │    Python Kernel                ││
│  │    - GPU/TPU Access            ││
│  │    - ML Libraries              ││
│  │    - Persistent /content       ││
│  └────────────────────────────────┘│
└─────────────────────────────────────┘
```

## Prerequisites

### Required

1. **Google Account** with Colab access
   - Free tier works, but Colab Pro recommended for:
     - Longer session times
     - Faster GPUs (T4, V100, A100)
     - More RAM

2. **Cloudflare Account** (free tier sufficient)
   - Domain managed by Cloudflare
   - Subdomain available (e.g., `colab.leonard-schneider.com`)

3. **Local Machine**
   - JupyterLab installed
   - MCP Server installed
   - Claude Desktop or Codex configured

### Optional

- **Google Drive** - for persisting tunnel credentials
- **Cloudflare Zero Trust** - for adding authentication

## Quick Start

### 1. Open Setup Notebook in Colab

1. Upload `colab/Colab_MCP_Setup.ipynb` to Google Colab
2. Or open directly: [Link to setup notebook]
3. Run all cells in order

### 2. Configure Cloudflare (One-Time)

In the Colab terminal:

```bash
# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create colab-tunnel

# Note the tunnel ID from output
# Save credentials
mkdir -p /content/tunnel-credentials
cp ~/.cloudflared/*.json /content/tunnel-credentials/

# Edit configuration
cp cloudflare-tunnel.yml.template /content/cloudflare-tunnel.yml
nano /content/cloudflare-tunnel.yml
# Replace YOUR_TUNNEL_ID_HERE with actual tunnel ID
```

### 3. Configure DNS

In Cloudflare Dashboard:

1. Go to DNS settings for your domain
2. Add CNAME record:
   - **Name**: `colab` (or full: `colab.leonard-schneider.com`)
   - **Target**: `<TUNNEL_ID>.cfargotunnel.com`
   - **Proxy status**: Proxied (orange cloud)

### 4. Start Services

Run in the setup notebook:

```python
!./start_jupyter_server.sh
!./start_cloudflare_tunnel.sh
```

### 5. Connect JupyterLab

On your local machine:

```bash
jupyter lab --gateway-url=https://colab.leonard-schneider.com
```

Or add the server in JupyterLab UI.

### 6. Verify

In JupyterLab, create a new notebook and run:

```python
import torch
print(f"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None'}")
```

You should see Colab's GPU!

## Detailed Setup

### Step 1: Cloudflare Tunnel Setup

#### A. Install cloudflared in Colab

This is handled by the setup script, but manually:

```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
```

#### B. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser window. Select your domain and authorize.

#### C. Create Tunnel

```bash
cloudflared tunnel create colab-tunnel
```

Output shows:
```
Tunnel credentials written to /root/.cloudflared/<TUNNEL_ID>.json
{"id":"<TUNNEL_ID>","name":"colab-tunnel",... }
```

**Important**: Save the TUNNEL_ID!

#### D. Configure Tunnel

Create `/content/cloudflare-tunnel.yml`:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /content/tunnel-credentials/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: colab.leonard-schneider.com
    service: http://localhost:8888
    originRequest:
      noTLSVerify: true
      httpHostHeader: localhost:8888
  - service: http_status:404

loglevel: info
metrics: localhost:2000
```

#### E. Set DNS

In Cloudflare Dashboard → DNS:

```
Type: CNAME
Name: colab
Target: <TUNNEL_ID>.cfargotunnel.com
Proxy: ON (orange cloud)
TTL: Auto
```

Wait 1-2 minutes for DNS propagation.

### Step 2: Jupyter Server Configuration

#### A. Install Dependencies

```bash
pip install jupyter-server jupyterlab jupyter_http_over_ws jupyter-collaboration
jupyter serverextension enable --py jupyter_http_over_ws
```

#### B. Configure Jupyter

Create `~/.jupyter/jupyter_server_config.py`:

```python
c = get_config()

# Remote access
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False

# No authentication (Cloudflare handles it)
c.ServerApp.token = ''
c.ServerApp.password = ''

# Disable XSRF for WebSocket
c.ServerApp.disable_check_xsrf = True

# Enable collaboration
c.ServerApp.jpserver_extensions = {
    'jupyter_server_collaboration': True
}

# Root directory
c.ServerApp.root_dir = '/content'
```

### Step 3: Persistence with Google Drive

#### A. Save Credentials

```bash
# Mount Drive
from google.colab import drive
drive.mount('/content/drive')

# Create backup directory
mkdir -p /content/drive/MyDrive/colab-tunnel

# Save credentials
cp -r /content/tunnel-credentials/* /content/drive/MyDrive/colab-tunnel/
cp /content/cloudflare-tunnel.yml /content/drive/MyDrive/colab-tunnel/
```

#### B. Restore on New Session

```bash
# Copy from Drive
cp /content/drive/MyDrive/colab-tunnel/*.json /content/tunnel-credentials/
cp /content/drive/MyDrive/colab-tunnel/cloudflare-tunnel.yml /content/
```

### Step 4: Starting Services

#### Manual Start

```bash
# Start Jupyter Server
nohup jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  > /tmp/jupyter-server.log 2>&1 &

# Start Cloudflare Tunnel
nohup cloudflared tunnel --config /content/cloudflare-tunnel.yml run \
  > /tmp/cloudflared.log 2>&1 &
```

#### Using Scripts

```bash
./start_jupyter_server.sh
./start_cloudflare_tunnel.sh
```

#### Verify Services

```bash
# Check processes
ps aux | grep -E 'jupyter|cloudflared'

# Check logs
tail -f /tmp/jupyter-server.log
tail -f /tmp/cloudflared.log

# Test endpoints
curl http://localhost:8888/api
curl https://colab.leonard-schneider.com/api
```

## Usage

### Starting a New Colab Session

1. **Open Colab notebook** with setup
2. **Restore credentials** from Google Drive
3. **Start services** with scripts
4. **Connect JupyterLab** locally
5. **Start working** with MCP Server

### Typical Workflow

```bash
# On local machine
$ jupyter lab --gateway-url=https://colab.leonard-schneider.com
# Browser opens with JupyterLab connected to Colab

# In another terminal
$ jupyter-mcp-server start
# MCP server connects to local JupyterLab

# In Claude Desktop
# Use MCP tools to create/edit/execute notebooks
# See changes live in JupyterLab browser tab
# Code executes on Colab GPU
```

### Working with Notebooks

```python
# In JupyterLab (connected to Colab)

# Create new notebook
# All execution happens on Colab hardware

import torch
import transformers

# This uses Colab's GPU!
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device}")

# Load a large model
model = transformers.AutoModel.from_pretrained('bert-large-uncased')
model.to(device)

# Your AI agent can interact with this notebook
# via MCP Server tools
```

### MCP Server Integration

Your existing MCP configuration works unchanged:

```json
{
  "mcpServers": {
    "jupyter": {
      "command": "jupyter-mcp-server",
      "args": ["start"],
      "env": {
        "JUPYTER_URL": "http://localhost:8888"
      }
    }
  }
}
```

## Troubleshooting

### Colab Session Disconnects

**Problem**: Colab runtime disconnects after inactivity

**Solutions**:
- Use Colab Pro for longer sessions
- Keep a cell running periodically:
  ```python
  import time
  while True:
      time.sleep(300)  # Every 5 minutes
      print("Keeping session alive...")
  ```
- Use browser extensions that prevent disconnection

### Tunnel Connection Issues

**Problem**: Cannot reach `https://colab.leonard-schneider.com`

**Diagnostics**:
```bash
# Check tunnel status
!ps aux | grep cloudflared

# Check logs
!tail -100 /tmp/cloudflared.log

# Test DNS
!nslookup colab.leonard-schneider.com

# Test local connectivity
!curl -I http://localhost:8888
```

**Solutions**:
- Restart tunnel: `pkill cloudflared && ./start_cloudflare_tunnel.sh`
- Check Cloudflare dashboard for tunnel status
- Verify DNS record is proxied (orange cloud)
- Check firewall rules in Cloudflare

### Jupyter Server Not Responding

**Problem**: Jupyter server doesn't start or crashes

**Diagnostics**:
```bash
# Check logs
!tail -100 /tmp/jupyter-server.log

# Check if port is in use
!lsof -i :8888

# Test directly
!curl -I http://localhost:8888/api
```

**Solutions**:
- Kill existing process: `pkill -f jupyter-lab`
- Check Python environment: `which python`
- Reinstall packages: `pip install --force-reinstall jupyter-server`
- Restart with verbose logging: `jupyter lab --debug`

### WebSocket Errors

**Problem**: JupyterLab connects but kernels don't work

**Solutions**:
1. Check browser console for WebSocket errors
2. Verify Cloudflare settings allow WebSockets
3. Check `jupyter_http_over_ws` is enabled:
   ```bash
   jupyter serverextension list
   ```
4. Try different browser

### Permission Errors

**Problem**: Cannot write files or access directories

**Solutions**:
- Check current directory: `!pwd`
- Verify permissions: `!ls -la /content`
- Ensure Jupyter root_dir is set correctly
- Try absolute paths: `/content/mynotebook.ipynb`

## FAQ

### Q: Do I need Colab Pro?

**A**: No, but recommended. Free tier limitations:
- 12-hour session limit
- May be interrupted during peak times
- Slower GPUs

### Q: Can I use multiple Colab sessions?

**A**: Yes! Set up different tunnels:
- `colab1.leonard-schneider.com` → First Colab session
- `colab2.leonard-schneider.com` → Second session
- Switch between them in JupyterLab

### Q: Is this secure?

**A**: Basic setup has no authentication. Recommendations:
- Use Cloudflare Access for authentication
- Restrict by IP in Cloudflare WAF
- Use complex subdomain name
- Monitor access logs

### Q: What about costs?

**A**:
- Colab Free: $0
- Colab Pro: ~$10/month
- Cloudflare Tunnel: Free
- Total: $0-10/month

### Q: Can I use TPUs?

**A**: Yes! Colab provides TPUs. In your notebook:
```python
import tensorflow as tf
print(f"TPU: {tf.config.list_logical_devices('TPU')}")
```

### Q: What happens when Colab disconnects?

**A**:
- Tunnel stops
- JupyterLab shows disconnected
- Restart services when you reconnect
- Files in `/content` may be lost (save to Drive!)

### Q: Can I customize the Python environment?

**A**: Yes! Install packages in Colab:
```bash
!pip install your-package
```

Or create custom conda environment.

### Q: How do I update the setup?

**A**:
- Pull latest scripts from repository
- Re-run setup notebook
- Restart services

## Best Practices

1. **Save work frequently** - Colab sessions can disconnect
2. **Use Google Drive** - Mount and save important files
3. **Version control** - Commit notebooks to Git
4. **Monitor resources** - Check GPU usage in Colab UI
5. **Document dependencies** - Keep `requirements.txt` updated
6. **Test connection** before long experiments
7. **Use Colab Pro** for production workflows
8. **Set up monitoring** - Track tunnel uptime
9. **Backup credentials** - Keep tunnel config in multiple places
10. **Secure access** - Add Cloudflare Access for production

## Next Steps

- [JupyterLab Connection Guide](JUPYTERLAB_CONNECTION.md)
- [MCP Server Documentation](../README.md)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Google Colab Docs](https://colab.research.google.com/)

## Support

- GitHub Issues: [Your repo URL]
- Cloudflare Community: https://community.cloudflare.com/
- JupyterLab Discourse: https://discourse.jupyter.org/

## Contributing

Improvements welcome! Areas for contribution:
- Auto-reconnection scripts
- Better error handling
- Additional cloud providers
- Enhanced security options
- Monitoring dashboards
