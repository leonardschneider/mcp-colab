# Google Colab Bridge for Jupyter MCP Server

Connect your local [Jupyter MCP Server](https://github.com/datalayer/jupyter-mcp-server) to Google Colab's GPU/TPU hardware with real-time collaboration support.

## 🎯 What This Does

Enables AI agents (Claude, Codex, etc.) to work with Jupyter notebooks running on **Google Colab's hardware** while you see changes **live** in your browser.

```
Your Machine:                Google Colab:
┌─────────────┐             ┌──────────────┐
│Claude/Codex │             │Jupyter Server│
│     ↓       │             │      ↓       │
│ MCP Server  │             │Python Kernel │
│     ↓       │             │  (GPU/TPU)   │
│ JupyterLab ─┼→Cloudflare─→│              │
└─────────────┘  Tunnel     └──────────────┘
```

## ✨ Features

- 🚀 **GPU/TPU Access**: Run experiments on Colab's powerful hardware
- 👀 **Real-time Updates**: See AI changes instantly via Jupyter RTC
- 🔌 **Zero MCP Changes**: Your existing MCP configuration works unchanged
- 🌐 **Persistent Domain**: Access via your subdomain (e.g., `colab.yourdomain.com`)
- 💾 **Drive Persistence**: Save tunnel credentials across sessions
- 🔒 **Secure**: HTTPS via Cloudflare tunnel

## 📋 Prerequisites

- Google Colab account (Pro recommended)
- Cloudflare account with a domain
- Local machine with:
  - [Jupyter MCP Server](https://github.com/datalayer/jupyter-mcp-server) installed
  - JupyterLab installed
  - Claude Desktop or other MCP client

## 🚀 Quick Start

### 1. Upload Setup Notebook

Upload `colab/Colab_MCP_Setup.ipynb` to Google Colab and run all cells.

### 2. Configure Cloudflare (One-Time)

In Colab terminal:
```bash
cloudflared tunnel login
cloudflared tunnel create colab-tunnel
```

Update DNS in Cloudflare Dashboard:
- CNAME: `colab.yourdomain.com` → `<TUNNEL_ID>.cfargotunnel.com`

### 3. Start Services

In Colab:
```bash
./start_jupyter_server.sh
./start_cloudflare_tunnel.sh
```

### 4. Connect JupyterLab

On your local machine:
```bash
jupyter lab --gateway-url=https://colab.yourdomain.com
```

### 5. Use MCP Server

Your existing configuration works as-is! The MCP server connects to your local JupyterLab, which is connected to Colab's kernel.

## 📚 Documentation

- **[Quick Start Guide](COLAB_QUICKSTART.md)** - 15-minute setup
- **[Complete Setup](docs/COLAB_SETUP.md)** - Detailed instructions
- **[JupyterLab Connection](docs/JUPYTERLAB_CONNECTION.md)** - Connection options

## 📁 Repository Structure

```
.
├── colab/
│   ├── Colab_MCP_Setup.ipynb          # Interactive setup notebook
│   ├── setup_jupyter_server.sh        # Install dependencies
│   ├── start_jupyter_server.sh        # Start Jupyter Server
│   ├── start_cloudflare_tunnel.sh     # Start tunnel
│   └── cloudflare-tunnel.yml.template # Tunnel configuration
├── docs/
│   ├── COLAB_SETUP.md                 # Complete setup guide
│   └── JUPYTERLAB_CONNECTION.md       # Connection instructions
├── COLAB_QUICKSTART.md                # Quick start guide
└── README.md                          # This file
```

## 🔄 Workflow

### First Setup (~15 minutes)
1. Configure Cloudflare tunnel
2. Upload and run setup notebook
3. Connect JupyterLab locally
4. Start using MCP server

### Subsequent Sessions (~2 minutes)
1. Restore credentials from Google Drive
2. Start services in Colab
3. Connect JupyterLab
4. Continue working

## 🛠️ Troubleshooting

See the [Complete Setup Guide](docs/COLAB_SETUP.md#troubleshooting) for detailed troubleshooting steps.

Common issues:
- **Tunnel not accessible**: Check DNS propagation, restart tunnel
- **Jupyter not responding**: Restart Jupyter Server
- **Colab disconnected**: Use Colab Pro, keep alive script

## 🔒 Security

Current setup:
- ✅ HTTPS via Cloudflare
- ⚠️ No Jupyter authentication (tunnel handles it)

**For production:**
- Add Cloudflare Access for authentication
- Use Cloudflare WAF to restrict access
- Monitor logs regularly

## 💡 Tips

1. **Save credentials to Google Drive** - Avoid reconfiguring each session
2. **Use Colab Pro** - Better GPUs, longer sessions
3. **Commit notebooks to Git** - Don't lose work
4. **Monitor Colab runtime** - Prevent idle disconnections
5. **Document dependencies** - Keep `requirements.txt` updated

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Auto-reconnection scripts
- Better error handling
- Monitoring dashboards
- Additional cloud providers

## 📄 License

BSD 3-Clause License - See LICENSE file

## 🔗 Related Projects

- [Jupyter MCP Server](https://github.com/datalayer/jupyter-mcp-server) - The MCP server this connects to
- [Model Context Protocol](https://modelcontextprotocol.io) - MCP specification
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) - Secure tunneling

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/colab-jupyter-bridge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/colab-jupyter-bridge/discussions)
- **Cloudflare**: [Community Forum](https://community.cloudflare.com/)
- **Jupyter**: [Discourse](https://discourse.jupyter.org/)

## ⭐ Star History

If you find this useful, please consider starring the repository!

---

**Made with ❤️ for the AI-assisted coding community**
