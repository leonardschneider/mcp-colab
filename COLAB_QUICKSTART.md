# Google Colab MCP Setup - Quick Start Guide

This guide gets you up and running with Jupyter MCP Server on Google Colab in **~15 minutes**.

## What You'll Get

- 🤖 AI agents (Claude/Codex) working with notebooks on Colab GPU/TPU
- 👀 Real-time visualization of changes in your browser
- 🌐 Persistent access via your domain: `colab.leonard-schneider.com`
- 🔄 No changes to your existing MCP Server configuration!

## Prerequisites

- ✅ Google Colab account (Pro recommended, free works)
- ✅ Cloudflare account (free tier OK)
- ✅ Domain in Cloudflare DNS
- ✅ Local machine with JupyterLab and MCP Server installed

## Setup Steps

### 1. Prepare Cloudflare (5 min, one-time)

**A. Login to Cloudflare**
- Go to https://dash.cloudflare.com
- Select your domain (leonard-schneider.com)

**B. Create DNS entry (placeholder)**
- Go to DNS section
- Add CNAME record:
  - **Name**: `colab`
  - **Target**: `placeholder.cfargotunnel.com` (we'll update this)
  - **Proxy**: ON (orange cloud)
- Save

### 2. Set Up Colab (10 min, first time; 2 min after)

**A. Open the setup notebook**
1. Go to https://colab.research.google.com
2. Upload `colab/Colab_MCP_Setup.ipynb` from this repository
3. Or create a new notebook and copy the content

**B. Run initial setup cells**
- Cell 1: Clone repository (or upload scripts manually)
- Cell 2: Run `setup_jupyter_server.sh`

**C. Configure Cloudflare Tunnel (first time only)**

Open Colab terminal (Tools → Command palette → "Terminal") and run:

```bash
# Login to Cloudflare (opens browser for auth)
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create colab-tunnel

# You'll see output like:
# Created tunnel colab-tunnel with id abc123-def456-...
# Credentials written to /root/.cloudflared/abc123-def456-....json
```

**Copy the tunnel ID!** (The long ID like `abc123-def456-...`)

**D. Save credentials**

In Colab terminal:

```bash
# Create credentials directory
mkdir -p /content/tunnel-credentials

# Copy credentials
cp ~/.cloudflared/*.json /content/tunnel-credentials/

# Create config from template
cp /content/mcp-colab/colab/cloudflare-tunnel.yml.template /content/cloudflare-tunnel.yml

# Edit config
nano /content/cloudflare-tunnel.yml
```

Replace `YOUR_TUNNEL_ID_HERE` in both places with your actual tunnel ID.

**E. Update DNS in Cloudflare**

Go back to Cloudflare Dashboard → DNS:
- Edit the `colab` CNAME record
- Change target to: `<YOUR_TUNNEL_ID>.cfargotunnel.com`
- Save

**F. Optional: Save to Google Drive (recommended)**

Run the "Save Credentials to Drive" cell in the notebook. This saves your tunnel config so you don't have to reconfigure every session.

**G. Start services**

Run these cells in the notebook:
```python
!./start_jupyter_server.sh
!./start_cloudflare_tunnel.sh
```

**H. Verify**

Run the verification cell. You should see:
```
✓ Jupyter Server is running locally
✓ Cloudflare Tunnel is working

🎉 Setup complete! Connect JupyterLab to:
   https://colab.leonard-schneider.com
```

### 3. Connect Local JupyterLab (2 min)

On your local machine, start JupyterLab connected to Colab:

```bash
jupyter lab --gateway-url=https://colab.leonard-schneider.com
```

Or add the server in JupyterLab UI:
- File → Hub Control Panel → Add Server
- URL: `https://colab.leonard-schneider.com`
- Token: (leave empty)
- Name: `Google Colab`

### 4. Verify Connection (1 min)

In JupyterLab, create a new notebook and run:

```python
# Check GPU
import torch
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")

# Check environment
import sys
print(f"Python: {sys.version}")

# Confirm Colab
try:
    import google.colab
    print("✓ Running on Google Colab!")
except:
    print("✗ Not on Colab")
```

You should see Colab's GPU info!

### 5. Use with MCP (Already working!)

Your existing MCP configuration doesn't change:

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

The MCP server talks to your **local** JupyterLab, which is connected to the **remote** Colab kernel. It just works!

## Subsequent Sessions

After the first setup, starting a new Colab session is quick:

1. **Open Colab notebook**
2. **Restore credentials** (run the "Restore from Drive" cell)
3. **Start services** (run the start cells)
4. **Connect JupyterLab** locally
5. **Start working!**

Takes ~2 minutes.

## Troubleshooting

### "Tunnel not accessible"

**Check:**
```bash
# In Colab
!ps aux | grep cloudflared
!tail /tmp/cloudflared.log
```

**Fix:**
- Restart tunnel: `!pkill cloudflared && ./start_cloudflare_tunnel.sh`
- Wait 1-2 min for DNS propagation
- Check Cloudflare Dashboard → Traffic → Tunnel status

### "Cannot connect to Jupyter"

**Check:**
```bash
# In Colab
!ps aux | grep jupyter
!tail /tmp/jupyter-server.log
!curl http://localhost:8888/api
```

**Fix:**
- Restart Jupyter: `!pkill jupyter && ./start_jupyter_server.sh`
- Check port 8888 is not in use: `!lsof -i :8888`

### "Colab session disconnected"

**Prevention:**
- Use Colab Pro (longer sessions)
- Keep a cell running to prevent idle disconnect
- Save credentials to Google Drive for quick restart

**Recovery:**
1. Reconnect Colab runtime
2. Restore credentials from Drive
3. Restart services

### "JupyterLab shows no kernels"

**Fix:**
- Check tunnel is working: `curl https://colab.leonard-schneider.com/api`
- Restart both Jupyter and tunnel
- Clear browser cache
- Try different browser

## Best Practices

1. **Save credentials to Google Drive** - Avoid reconfiguring each session
2. **Use Colab Pro** - Better GPUs, longer sessions
3. **Monitor Colab runtime** - Don't let it idle too long
4. **Test connection** before starting long experiments
5. **Commit notebooks to Git** - Colab can lose unsaved work
6. **Use requirements.txt** - Document package dependencies

## Security Notes

Current setup has no authentication on Jupyter (Cloudflare tunnel handles security).

**For production:**
- Add Cloudflare Access authentication
- Use Cloudflare WAF to restrict by IP
- Monitor access logs
- Rotate tunnel credentials periodically

## What's Next?

- 📘 [Detailed Setup Guide](docs/COLAB_SETUP.md) - Complete instructions
- 🔗 [JupyterLab Connection](docs/JUPYTERLAB_CONNECTION.md) - Advanced config
- 🎯 [MCP Server Docs](https://jupyter-mcp-server.datalayer.tech/) - Tool reference

## Support

- **Issues**: Open a GitHub issue
- **Cloudflare**: https://community.cloudflare.com/
- **Jupyter**: https://discourse.jupyter.org/

## Summary

You now have:
- ✅ Jupyter Server running in Colab
- ✅ Accessible via your subdomain through Cloudflare
- ✅ Local JupyterLab connected to remote Colab kernel
- ✅ MCP Server working with GPU-accelerated notebooks
- ✅ Real-time collaboration with AI agents

**Happy experimenting! 🚀**
