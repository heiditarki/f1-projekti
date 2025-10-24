#!/bin/bash
# F1 Backend Server Startup Script
# This script ensures the backend server starts reliably

cd "$(dirname "$0")"

echo "Starting F1 Backend Server..."
echo "Working directory: $(pwd)"

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "Error: Virtual environment not found!"
    exit 1
fi

# Check if port 8000 is already in use
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 8000 is already in use. Killing existing processes..."
    pkill -f uvicorn || true
    pkill -f "python.*app" || true
    sleep 2
fi

# Start the server
echo "Starting server..."
uvicorn app:app --host 127.0.0.1 --port 8000 --reload --log-level info
