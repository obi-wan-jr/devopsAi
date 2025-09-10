#!/bin/bash

# Model Setup Script - Download and configure Qwen2 1.5B model
# This script can be run independently to setup just the model

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
MODEL_NAME="qwen2-1.5b-q4_k_m.gguf"
MODEL_REPO="Qwen/Qwen2-1.5B-GGUF"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

# Check if project directory exists
if [[ ! -d "$PROJECT_DIR" ]]; then
    log_error "Project directory not found: $PROJECT_DIR"
    log_info "Please run install.sh first"
    exit 1
fi

cd "$PROJECT_DIR"

# Activate virtual environment
if [[ -d "ai-agent-env" ]]; then
    source ai-agent-env/bin/activate
else
    log_error "Virtual environment not found. Please run install.sh first"
    exit 1
fi

# Create models directory
mkdir -p models

# Install huggingface-hub if not present
pip install huggingface-hub

# Download model
log_info "Downloading Qwen2 1.5B model..."
python3 -c "
from huggingface_hub import hf_hub_download
import os
os.chdir('models')
try:
    hf_hub_download(
        repo_id='$MODEL_REPO',
        filename='$MODEL_NAME',
        local_dir='.',
        local_dir_use_symlinks=False
    )
    print('Model downloaded successfully')
except Exception as e:
    print(f'Error downloading model: {e}')
    exit(1)
"

# Verify download
if [[ -f "models/$MODEL_NAME" ]]; then
    MODEL_SIZE=$(du -h "models/$MODEL_NAME" | cut -f1)
    log_success "Model downloaded successfully: $MODEL_NAME ($MODEL_SIZE)"
else
    log_error "Model download failed"
    exit 1
fi

# Test model loading
log_info "Testing model loading..."
python3 -c "
from llama_cpp import Llama
import sys
try:
    llm = Llama(model_path='models/$MODEL_NAME', n_ctx=512, verbose=False)
    print('Model loaded successfully')
    # Test inference
    response = llm('Hello, how are you?', max_tokens=10)
    print('Model inference test passed')
except Exception as e:
    print(f'Model test failed: {e}')
    sys.exit(1)
"

log_success "Model setup completed successfully!"
