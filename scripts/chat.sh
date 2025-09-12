#!/bin/bash

# AI System Administrator Agent - Terminal Chat Interface
# Provides an interactive terminal interface to chat with the remote LLM

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"
API_URL="http://localhost:4000"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're running locally or remotely
if [[ "$1" == "--remote" ]]; then
    log_info "Starting remote terminal chat session..."
    ssh "$REMOTE_USER@$REMOTE_HOST" "cd $PROJECT_DIR && python3 src/cli_chat.py --url $API_URL"
elif [[ "$1" == "--local" ]]; then
    log_info "Starting local terminal chat session..."
    python3 src/cli_chat.py --url "http://192.168.50.239:4000"
else
    echo "AI System Administrator Agent - Terminal Chat Interface"
    echo "======================================================"
    echo
    echo "Usage: $0 [option]"
    echo
    echo "Options:"
    echo "  --remote    Connect to the agent running on the Raspberry Pi"
    echo "  --local     Connect to the agent from your local machine"
    echo "  --help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --remote    # SSH to Pi and start interactive chat"
    echo "  $0 --local     # Connect from local machine to Pi's API"
    echo
    echo "Interactive Commands (once connected):"
    echo "  /help     - Show help"
    echo "  /models   - List available models"
    echo "  /model qwen3 - Switch to Qwen3-4B-Thinking model"
    echo "  /auto     - Use automatic model selection"
    echo "  /quit     - Exit the chat"
    echo
    echo "Single Message Examples:"
    echo "  ssh inggo@meatpi 'cd /home/inggo/ai-agent && python3 src/cli_chat.py \"Check my system status\"'"
    echo "  python3 src/cli_chat.py --url http://192.168.50.239:4000 \"Help me troubleshoot my server\""
    echo
fi