#!/bin/bash

# AI System Administrator Agent - Installation Script for Raspberry Pi 5
# This script installs and configures the AI agent on Raspberry Pi 5 (ARM64)

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
PYTHON_VERSION="3.11"
VENV_NAME="ai-agent-env"
MODEL_NAME="qwen2-1.5b-q4_k_m.gguf"
MODEL_URL="https://huggingface.co/Qwen/Qwen2-1.5B-GGUF/resolve/main/qwen2-1.5b-q4_k_m.gguf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_user() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as user 'inggo'."
        exit 1
    fi
    
    if [[ "$USER" != "inggo" ]]; then
        log_warning "This script is designed for user 'inggo'. Current user: $USER"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check system requirements
check_system() {
    log_info "Checking system requirements..."
    
    # Check if running on Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log_warning "This script is designed for Raspberry Pi. Continue anyway? (y/N)"
        read -p "" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        log_warning "Expected ARM64 architecture, found: $ARCH"
    fi
    
    # Check available memory
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $MEMORY_GB -lt 4 ]]; then
        log_warning "Less than 4GB RAM detected. Performance may be limited."
    fi
    
    # Check available disk space
    DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $DISK_GB -lt 10 ]]; then
        log_error "Less than 10GB free disk space. Please free up space."
        exit 1
    fi
    
    log_success "System requirements check passed"
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    
    sudo apt update
    sudo apt upgrade -y
    
    # Install essential packages
    sudo apt install -y \
        build-essential \
        cmake \
        git \
        curl \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        libffi-dev \
        libssl-dev \
        pkg-config \
        htop \
        tree \
        jq
    
    log_success "System packages updated"
}

# Install Python dependencies
install_python_deps() {
    log_info "Installing Python dependencies..."
    
    # Create project directory
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # Create virtual environment
    python3 -m venv "$VENV_NAME"
    source "$VENV_NAME/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install wheel and setuptools
    pip install wheel setuptools
    
    # Install PyTorch for ARM64 (if available)
    log_info "Installing PyTorch for ARM64..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    
    # Install other requirements
    pip install -r requirements.txt
    
    log_success "Python dependencies installed"
}

# Download and setup LLM model
setup_model() {
    log_info "Setting up LLM model..."
    
    cd "$PROJECT_DIR"
    source "$VENV_NAME/bin/activate"
    
    # Create models directory
    mkdir -p models
    
    # Download model if not exists
    if [[ ! -f "models/$MODEL_NAME" ]]; then
        log_info "Downloading Qwen2 1.5B model (this may take a while)..."
        
        # Install huggingface-hub if not already installed
        pip install huggingface-hub
        
        # Download model
        python3 -c "
from huggingface_hub import hf_hub_download
import os
os.chdir('models')
hf_hub_download(
    repo_id='Qwen/Qwen2-1.5B-GGUF',
    filename='$MODEL_NAME',
    local_dir='.',
    local_dir_use_symlinks=False
)
"
        
        if [[ ! -f "models/$MODEL_NAME" ]]; then
            log_error "Failed to download model"
            exit 1
        fi
    else
        log_info "Model already exists, skipping download"
    fi
    
    # Verify model file
    MODEL_SIZE=$(du -h "models/$MODEL_NAME" | cut -f1)
    log_success "Model downloaded: $MODEL_NAME ($MODEL_SIZE)"
}

# Setup llama.cpp
setup_llama_cpp() {
    log_info "Setting up llama.cpp..."
    
    cd "$PROJECT_DIR"
    
    # Clone llama.cpp if not exists
    if [[ ! -d "llama.cpp" ]]; then
        git clone https://github.com/ggerganov/llama.cpp.git
    fi
    
    cd llama.cpp
    
    # Build with ARM64 optimizations
    make clean
    make -j$(nproc) LLAMA_OPENBLAS=1
    
    # Test the build
    if [[ -f "server" ]]; then
        log_success "llama.cpp built successfully"
    else
        log_error "Failed to build llama.cpp"
        exit 1
    fi
}

# Setup systemd service
setup_service() {
    log_info "Setting up systemd service..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/ai-sysadmin-agent.service > /dev/null <<EOF
[Unit]
Description=AI System Administrator Agent
After=network.target
Wants=network.target

[Service]
Type=simple
User=inggo
Group=inggo
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/$VENV_NAME/bin
ExecStart=$PROJECT_DIR/$VENV_NAME/bin/python -m src.main
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$PROJECT_DIR
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable ai-sysadmin-agent.service
    
    log_success "Systemd service configured"
}

# Setup firewall
setup_firewall() {
    log_info "Setting up firewall..."
    
    # Install ufw if not present
    sudo apt install -y ufw
    
    # Configure firewall rules
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow web interface
    sudo ufw allow 8080/tcp
    sudo ufw allow 8081/tcp
    sudo ufw allow 8082/tcp
    
    # Enable firewall
    sudo ufw --force enable
    
    log_success "Firewall configured"
}

# Create startup script
create_startup_script() {
    log_info "Creating startup script..."
    
    cd "$PROJECT_DIR"
    
    # Create start script
    cat > start.sh <<'EOF'
#!/bin/bash

# AI System Administrator Agent - Startup Script

PROJECT_DIR="/home/inggo/ai-agent"
VENV_NAME="ai-agent-env"

cd "$PROJECT_DIR"
source "$VENV_NAME/bin/activate"

# Start llama.cpp server in background
if [[ ! -f "llama.cpp/server" ]]; then
    echo "Error: llama.cpp server not found. Please run install.sh first."
    exit 1
fi

echo "Starting llama.cpp server..."
cd llama.cpp
./server -m "$PROJECT_DIR/models/qwen2-1.5b-q4_k_m.gguf" --host 0.0.0.0 --port 8082 &
LLAMA_PID=$!

# Wait for server to start
sleep 5

# Start the main agent
echo "Starting AI System Administrator Agent..."
cd "$PROJECT_DIR"
python -m src.main

# Cleanup on exit
echo "Shutting down..."
kill $LLAMA_PID 2>/dev/null
EOF

    chmod +x start.sh
    
    log_success "Startup script created"
}

# Main installation function
main() {
    log_info "Starting AI System Administrator Agent installation..."
    
    check_user
    check_system
    update_system
    install_python_deps
    setup_model
    setup_llama_cpp
    setup_service
    setup_firewall
    create_startup_script
    
    log_success "Installation completed successfully!"
    
    echo
    log_info "Next steps:"
    echo "1. Start the service: sudo systemctl start ai-sysadmin-agent"
    echo "2. Check status: sudo systemctl status ai-sysadmin-agent"
    echo "3. View logs: sudo journalctl -u ai-sysadmin-agent -f"
    echo "4. Access web interface: http://$(hostname -I | awk '{print $1}'):8080"
    echo "5. Or run manually: cd $PROJECT_DIR && ./start.sh"
    
    echo
    log_info "Configuration files are in: $PROJECT_DIR/config/"
    log_info "Logs are in: $PROJECT_DIR/logs/"
    log_info "Model is in: $PROJECT_DIR/models/"
}

# Run main function
main "$@"
