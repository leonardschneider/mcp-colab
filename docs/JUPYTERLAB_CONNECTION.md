# Connecting JupyterLab to Remote Colab Server

This guide explains how to connect your local JupyterLab installation to a Jupyter Server running in Google Colab.

## Prerequisites

1. Jupyter Server running in Colab (via setup notebook)
2. Cloudflare tunnel active and accessible
3. Local JupyterLab installed on your machine

## Installation

If you don't have JupyterLab installed locally:

```bash
pip install jupyterlab jupyter-collaboration
```

## Connection Methods

### Method 1: Via Command Line (Recommended)

Start JupyterLab directly connected to the remote Colab server:

```bash
jupyter lab --gateway-url=https://colab.leonard-schneider.com
```

This is the simplest method - JupyterLab will connect to Colab's Jupyter server instead of starting a local one.

Or use the `JUPYTER_GATEWAY_URL` environment variable:

```bash
export JUPYTER_GATEWAY_URL=https://colab.leonard-schneider.com
jupyter lab
```

### Method 2: Via Configuration File

Create or edit `~/.jupyter/jupyter_lab_config.py`:

```python
c = get_config()

# Connect to remote Jupyter server
c.ServerApp.gateway_url = 'https://colab.leonard-schneider.com'
```

Then start JupyterLab normally:
```bash
jupyter lab
```

## Verifying Connection

Once connected, you should see:

1. **Server indicator**: Shows you're connected to the remote server
2. **File browser**: Shows `/content` directory from Colab
3. **Available kernels**: Should include Python 3 with access to Colab packages

### Test the Connection

Create a new notebook and run:

```python
# Check if running on Colab
try:
    import google.colab
    print("✓ Running on Google Colab!")
except ImportError:
    print("✗ Not running on Colab")

# Check GPU availability
import torch
if torch.cuda.is_available():
    print(f"✓ GPU available: {torch.cuda.get_device_name(0)}")
    print(f"  GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
else:
    print("ℹ No GPU detected (CPU mode)")

# Check available packages
import sys
print(f"\nPython version: {sys.version}")
print(f"Running from: {sys.executable}")
```

## Using with MCP Server

Your existing Jupyter MCP Server configuration should work without changes!

### MCP Server Configuration

If using with Claude Desktop, your `claude_desktop_config.json` remains the same:

```json
{
  "mcpServers": {
    "jupyter": {
      "command": "jupyter-mcp-server",
      "args": ["start"],
      "env": {
        "JUPYTER_URL": "http://localhost:8888",
        "JUPYTER_TOKEN": ""
      }
    }
  }
}
```

The MCP server connects to your **local** JupyterLab, which is connected to the **remote** Colab kernel. The MCP server doesn't know the difference!

### Workflow

```
Claude Desktop
      ↓
  MCP Server (local)
      ↓
  JupyterLab (local)
      ↓ (HTTPS/WebSocket)
  Cloudflare Tunnel
      ↓
  Jupyter Server (Colab)
      ↓
  Python Kernel with GPU
```

## Real-Time Collaboration

The setup supports real-time collaboration via Jupyter's RTC (Real-Time Collaboration):

1. **Open a notebook in JupyterLab** (local, connected to Colab)
2. **Run MCP Server tools** (via Claude/Codex)
3. **See changes live** in your JupyterLab browser tab
4. **Execution happens on Colab GPU/TPU**

This is the same experience as using JupyterLab locally, but with Colab's hardware!

## Troubleshooting

### Connection Refused

**Problem**: Cannot connect to `https://colab.leonard-schneider.com`

**Solutions**:
1. Check Colab session is still active
2. Verify tunnel is running: `!ps aux | grep cloudflared`
3. Check tunnel logs: `!tail /tmp/cloudflared.log`
4. Verify DNS: `dig colab.leonard-schneider.com`

### No Kernels Available

**Problem**: JupyterLab shows no available kernels

**Solutions**:
1. Check Jupyter Server logs in Colab: `!tail /tmp/jupyter-server.log`
2. Restart Jupyter Server: `!./start_jupyter_server.sh`
3. Verify kernel is running: `jupyter kernelspec list`

### WebSocket Connection Failed

**Problem**: JupyterLab connects but cells don't execute

**Solutions**:
1. Check firewall/network settings
2. Verify Cloudflare tunnel supports WebSockets (should by default)
3. Check browser console for errors
4. Try different browser (Chrome/Firefox recommended)

### "Cannot connect to remote server"

**Problem**: JupyterLab shows server offline

**Solutions**:
1. Check Colab runtime didn't disconnect
2. Verify services still running:
   ```bash
   !ps aux | grep -E 'jupyter|cloudflared'
   ```
3. Restart both services if needed

### Token/Authentication Errors

**Problem**: Asks for token despite configuration

**Solutions**:
1. Verify Jupyter config has `c.ServerApp.token = ''`
2. Check Colab server config: `!cat ~/.jupyter/jupyter_server_config.py`
3. Restart Jupyter Server after config changes

## Advanced Configuration

### Using Multiple Colab Runtimes

You can connect to different Colab sessions by:

1. Setting up tunnels on different domains/subdomains
2. Using different ports with the same tunnel
3. Switching servers in JupyterLab

### Adding Authentication

For production use, add Cloudflare Access:

1. Go to Cloudflare Dashboard → Zero Trust
2. Create Access Policy for `colab.leonard-schneider.com`
3. Require authentication (Google, email, etc.)
4. No changes needed to Jupyter config

### Custom Kernel Configurations

Add custom kernels in Colab:

```bash
# Install custom kernel
pip install ipykernel
python -m ipykernel install --user --name myenv --display-name "My Custom Env"
```

These will appear in JupyterLab's kernel selector.

## Best Practices

1. **Save credentials to Google Drive** to avoid reconfiguration each session
2. **Use Colab Pro** for longer session times and faster GPUs
3. **Monitor Colab runtime** - free tier disconnects after inactivity
4. **Test connection** before starting long experiments
5. **Use version control** - commit notebooks to Git regularly
6. **Keep tunnel running** - add monitoring/auto-restart if needed

## Security Considerations

### Current Setup

- ✅ HTTPS via Cloudflare tunnel
- ✅ Isolated Colab runtime environment
- ⚠️ No token authentication on Jupyter
- ⚠️ Anyone with URL can access (if DNS is public)

### Recommended for Production

1. **Add Cloudflare Access** for authentication
2. **Use Cloudflare WAF** to restrict by IP
3. **Monitor access logs** in Cloudflare dashboard
4. **Rotate tunnel credentials** periodically
5. **Use separate Google account** for Colab experiments

## Next Steps

- [MCP Server Documentation](../README.md)
- [Colab Setup Guide](COLAB_SETUP.md)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
