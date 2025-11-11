#!/bin/bash
# Start Jupyter Server in background

echo "Starting Jupyter Server..."

# Kill any existing Jupyter server
pkill -f "jupyter-lab" || true
pkill -f "jupyter lab" || true

# Start Jupyter Server in background
nohup jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    > /tmp/jupyter-server.log 2>&1 &

JUPYTER_PID=$!

echo "Jupyter Server started with PID: $JUPYTER_PID"
echo "Logs: /tmp/jupyter-server.log"
echo ""
echo "To view logs: tail -f /tmp/jupyter-server.log"
echo "To stop: kill $JUPYTER_PID"
echo ""

# Wait a moment and check if it's running
sleep 3

if ps -p $JUPYTER_PID > /dev/null; then
    echo "✓ Jupyter Server is running"
    echo "  Local access: http://localhost:8888"
else
    echo "✗ Jupyter Server failed to start"
    echo "  Check logs at /tmp/jupyter-server.log"
    exit 1
fi
