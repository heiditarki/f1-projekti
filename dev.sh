#!/bin/bash
# F1 Project Development Script
# Starts both frontend and backend with proper coordination

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup on exit
cleanup() {
    print_status "Shutting down development servers..."
    pkill -f "elm-live" || true
    pkill -f "uvicorn" || true
    pkill -f "python.*app" || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

print_status "F1 Project Development Environment"
print_status "Project root: $PROJECT_ROOT"

# Check if directories exist
if [ ! -d "$BACKEND_DIR" ]; then
    print_error "Backend directory not found: $BACKEND_DIR"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

# Kill any existing processes
print_status "Cleaning up existing processes..."
pkill -f "elm-live" || true
pkill -f "uvicorn" || true
pkill -f "python.*app" || true
sleep 2

# Start backend
print_status "Starting backend server..."
cd "$BACKEND_DIR"

if [ ! -f "venv/bin/activate" ]; then
    print_error "Virtual environment not found in backend directory"
    exit 1
fi

source venv/bin/activate

# Start backend in background
uvicorn app:app --host 127.0.0.1 --port 8000 --reload --log-level info &
BACKEND_PID=$!

# Wait for backend to start
print_status "Waiting for backend to start..."
sleep 3

# Test backend
if curl -s http://127.0.0.1:8000/races/2024 > /dev/null; then
    print_success "Backend server started successfully on http://127.0.0.1:8000"
else
    print_error "Backend server failed to start"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# Start frontend
print_status "Starting frontend development server..."
cd "$FRONTEND_DIR"

if [ ! -f "package.json" ]; then
    print_error "package.json not found in frontend directory"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# Start frontend in background
npm start &
FRONTEND_PID=$!

# Wait for frontend to start
print_status "Waiting for frontend to start..."
sleep 5

print_success "Development environment started!"
print_status "Backend: http://127.0.0.1:8000"
print_status "Frontend: http://localhost:3000"
print_status ""
print_status "Press Ctrl+C to stop all servers"

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
