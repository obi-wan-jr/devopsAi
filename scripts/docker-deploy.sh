#!/bin/bash

# Docker Deployment Script for AI System Administrator Agent on Raspberry Pi 5
# This script handles Docker-based deployment to meatpi

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"  # Change this to your Pi's hostname or IP
REMOTE_USER="inggo"
LOCAL_PROJECT_DIR="/Users/inggo/Documents/ai-sysadmin-agent"
DOCKER_COMPOSE_FILE="docker-compose.yml"

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

# Check if we're in the right directory
check_local_directory() {
    if [[ ! -f "docker-compose.yml" ]] || [[ ! -f "Dockerfile" ]]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    log_success "Local project directory verified"
}

# Test SSH connection
test_ssh_connection() {
    log_info "Testing SSH connection to $REMOTE_HOST..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" exit 2>/dev/null; then
        log_success "SSH connection successful"
    else
        log_error "SSH connection failed. Please check:"
        echo "1. SSH key is set up correctly"
        echo "2. Hostname/IP is correct: $REMOTE_HOST"
        echo "3. User exists: $REMOTE_USER"
        echo "4. SSH service is running on the Pi"
        exit 1
    fi
}

# Check Docker installation on remote host
check_docker_installation() {
    log_info "Checking Docker installation on $REMOTE_HOST..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        if command -v docker >/dev/null 2>&1; then
            echo 'Docker is installed'
            docker --version
        else
            echo 'Docker not found. Installing Docker...'
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            echo 'Docker installed. Please log out and back in, then run this script again.'
            exit 1
        fi
        
        if command -v docker-compose >/dev/null 2>&1; then
            echo 'Docker Compose is installed'
            docker-compose --version
        else
            echo 'Installing Docker Compose...'
            sudo apt update
            sudo apt install -y docker-compose-plugin
            echo 'Docker Compose installed'
        fi
    "
    
    log_success "Docker environment verified"
}

# Setup remote directory structure
setup_remote_directory() {
    log_info "Setting up remote directory structure..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        mkdir -p $PROJECT_DIR/{models,logs,config}
        mkdir -p $PROJECT_DIR/models
    "
    
    log_success "Remote directory structure created"
}

# Copy Docker files
copy_docker_files() {
    log_info "Copying Docker files to $REMOTE_HOST..."
    
    # Copy Docker configuration files
    rsync -avz --progress \
        docker-compose.yml \
        Dockerfile \
        Dockerfile.llama \
        requirements.txt \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/"
    
    # Copy source code
    rsync -avz --progress \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.env' \
        --exclude='models/' \
        --exclude='logs/' \
        --exclude='ai-agent-env/' \
        src/ \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/src/"
    
    # Copy configuration files
    rsync -avz --progress \
        config/ \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/config/"
    
    log_success "Docker files copied"
}

# Download model on remote host
download_model() {
    log_info "Downloading model on remote host..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Check if model already exists
        if [[ -f 'models/qwen2-1.5b-q4_k_m.gguf' ]]; then
            echo 'Model already exists, skipping download'
        else
            echo 'Downloading Qwen2 1.5B model...'
            docker run --rm -v \$(pwd)/models:/models \
                huggingface/hub-download:latest \
                --repo-id Qwen/Qwen2-1.5B-GGUF \
                --filename qwen2-1.5b-q4_k_m.gguf \
                --local-dir /models
        fi
        
        # Verify model file
        if [[ -f 'models/qwen2-1.5b-q4_k_m.gguf' ]]; then
            echo 'Model downloaded successfully'
            ls -lh models/qwen2-1.5b-q4_k_m.gguf
        else
            echo 'Model download failed'
            exit 1
        fi
    "
    
    log_success "Model downloaded"
}

# Build Docker images
build_docker_images() {
    log_info "Building Docker images on $REMOTE_HOST..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Build main application image
        echo 'Building main application image...'
        docker build -t ai-sysadmin-agent:latest .
        
        # Build llama.cpp server image
        echo 'Building llama.cpp server image...'
        docker build -f Dockerfile.llama -t llama-server:latest .
        
        # List built images
        docker images | grep -E '(ai-sysadmin-agent|llama-server)'
    "
    
    log_success "Docker images built"
}

# Start Docker services
start_docker_services() {
    log_info "Starting Docker services..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Stop existing services if running
        docker-compose down 2>/dev/null || true
        
        # Start services
        docker-compose up -d
        
        # Wait for services to start
        sleep 10
        
        # Check service status
        docker-compose ps
    "
    
    log_success "Docker services started"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Get the Pi's IP address
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    log_info "Testing web interface..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8080/health" | grep -q "200"; then
        log_success "Web interface is responding"
    else
        log_warning "Web interface may not be ready yet"
    fi
    
    log_info "Testing API endpoint..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8081/api/status" | grep -q "200"; then
        log_success "API endpoint is responding"
    else
        log_warning "API endpoint may not be ready yet"
    fi
    
    log_info "Testing llama server..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8082/health" | grep -q "200"; then
        log_success "LLM server is responding"
    else
        log_warning "LLM server may not be ready yet"
    fi
    
    log_success "Deployment verification completed"
}

# Show deployment summary
show_summary() {
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    echo
    log_success "🎉 Docker deployment completed successfully!"
    echo
    log_info "Access your AI System Administrator Agent:"
    echo "  🌐 Web Interface: http://$PI_IP:8080"
    echo "  🔌 API Endpoint: http://$PI_IP:8081"
    echo "  🧠 LLM Server: http://$PI_IP:8082"
    echo "  📊 Health Check: http://$PI_IP:8080/health"
    echo
    log_info "Docker management commands:"
    echo "  📋 Check status: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose ps'"
    echo "  📝 View logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose logs -f'"
    echo "  🔄 Restart: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose restart'"
    echo "  🛑 Stop: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose down'"
    echo "  🗑️  Cleanup: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose down -v'"
    echo
    log_info "Docker images:"
    echo "  🐳 Main App: ai-sysadmin-agent:latest"
    echo "  🧠 LLM Server: llama-server:latest"
    echo
}

# Main deployment function
main() {
    log_info "Starting Docker deployment to $REMOTE_HOST..."
    
    check_local_directory
    test_ssh_connection
    check_docker_installation
    setup_remote_directory
    copy_docker_files
    download_model
    build_docker_images
    start_docker_services
    verify_deployment
    show_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --test-only    Only test SSH connection and Docker"
        echo "  --build-only   Only build images (skip deployment)"
        echo
        echo "Environment variables:"
        echo "  REMOTE_HOST    Remote hostname or IP (default: meatpi)"
        echo "  REMOTE_USER    Remote username (default: inggo)"
        echo
        exit 0
        ;;
    --test-only)
        test_ssh_connection
        check_docker_installation
        log_success "Docker environment test passed"
        exit 0
        ;;
    --build-only)
        check_local_directory
        test_ssh_connection
        check_docker_installation
        setup_remote_directory
        copy_docker_files
        download_model
        build_docker_images
        log_success "Docker images built successfully"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
