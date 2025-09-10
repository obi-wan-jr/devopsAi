#!/bin/bash

# AI System Administrator Agent - Chat Script
# Simple wrapper for the CLI chat interface

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default API URL (can be overridden with environment variable)
API_URL="${API_URL:-http://localhost:9000}"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Check if httpx is available
if ! python3 -c "import httpx" 2>/dev/null; then
    echo "❌ httpx library is required. Installing..."
    pip3 install httpx
fi

# Run the CLI chat
echo "🚀 Starting AI System Administrator Agent Chat..."
echo "📍 API URL: $API_URL"
echo ""

cd "$PROJECT_DIR"
python3 src/cli_chat.py --url "$API_URL" "$@"
