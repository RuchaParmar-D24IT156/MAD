"""
run_server.py  –  Start the SakshmSeva Gujarat API server.

Usage:
    python run_server.py

This starts the FastAPI server from sgp/api.py on port 8000.
The Flutter app's chatbot (Ask Sakshm) connects to this server.
"""
import subprocess
import sys
import os

if __name__ == "__main__":
    sgp_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sgp")
    print("=" * 55)
    print("  SakshmSeva Gujarat API Server")
    print("  Starting on http://136.233.130.145:8000")
    print("  Flutter chatbot connects to this.")
    print("  Press Ctrl+C to stop.")
    print("=" * 55)
    subprocess.run(
        [sys.executable, "-m", "uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000", "--reload"],
        cwd=sgp_dir,
    )
