#!/usr/bin/env python3
"""
Stable FastAPI server startup script for F1 project backend.
This script ensures proper environment setup and stable server operation.
"""

import os
import sys
import subprocess
import signal
import time
from pathlib import Path


def setup_environment():
    """Setup the Python environment and cache directory."""
    # Set up cache directory
    cache_dir = Path("f1_cache")
    cache_dir.mkdir(exist_ok=True)

    # Set environment variables for better stability
    os.environ["PYTHONPATH"] = str(Path.cwd())
    os.environ["FASTF1_CACHE"] = str(cache_dir.absolute())

    print(f"Cache directory: {cache_dir.absolute()}")
    print(f"Python path: {sys.executable}")
    print(f"Working directory: {Path.cwd()}")


def start_server():
    """Start the FastAPI server with proper configuration."""
    setup_environment()

    # Server configuration
    host = "127.0.0.1"
    port = 8000
    reload = True

    print(f"Starting FastAPI server on {host}:{port}")
    print("Press Ctrl+C to stop the server")

    try:
        # Import uvicorn
        import uvicorn

        # Start server with proper configuration
        uvicorn.run(
            "app:app",  # Use import string for reload mode
            host=host,
            port=port,
            reload=reload,
            log_level="info",
            access_log=True,
            # Add stability options
            loop="asyncio",
            http="httptools",
            # Prevent hanging on shutdown
            timeout_keep_alive=30,
            timeout_graceful_shutdown=10,
        )

    except KeyboardInterrupt:
        print("\nShutting down server...")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)


if __name__ == "__main__":
    start_server()
