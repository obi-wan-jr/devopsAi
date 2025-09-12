#!/bin/bash

# Remote LLM Deployment Script for AI System Administrator Agent on Raspberry Pi 5 "meatpi"
# Features: Remote Qwen3-4B-Thinking + API Gateway + Wiki.js
# Uses remote LLM service at http://100.79.227.126:1234

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"
LOCAL_PROJECT_DIR="/Users/inggo/Documents/ai-sysadmin-agent"
DOCKER_COMPOSE_FILE="docker-compose.remote-llm.yml"

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
    if [[ ! -f "docker-compose.remote-llm.yml" ]] || [[ ! -f "Dockerfile.gateway.pi" ]]; then
        log_error "Please run this script from the project root directory"
        log_error "Required files: docker-compose.remote-llm.yml, Dockerfile.gateway.pi"
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
        mkdir -p $PROJECT_DIR/{logs,config,data/wiki}
        mkdir -p $PROJECT_DIR/logs/wiki
        chmod 755 $PROJECT_DIR/data/wiki
        chmod 755 $PROJECT_DIR/logs/wiki
    "
    
    log_success "Remote directory structure created"
}

# Pull latest code from Git
pull_latest_code() {
    log_info "Pulling latest code from Git repository..."
    
    # Check if we're in a git repository
    if [[ -d ".git" ]]; then
        log_info "Pulling latest changes from Git..."
        git pull origin main || log_warning "Git pull failed or no remote configured"
    else
        log_warning "Not in a Git repository, skipping Git pull"
    fi
    
    log_success "Code synchronization completed"
}

# Copy deployment files
copy_deployment_files() {
    log_info "Copying deployment files to $REMOTE_HOST..."
    
    # Copy Docker configuration files
    rsync -avz --progress \
        docker-compose.remote-llm.yml \
        Dockerfile.gateway.pi \
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
    
    # Copy scripts
    rsync -avz --progress \
        scripts/ \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/scripts/"
    
    # Make scripts executable
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        chmod +x $PROJECT_DIR/scripts/*.sh
    "
    
    log_success "Deployment files copied"
}

# Test remote LLM connection
test_remote_llm() {
    log_info "Testing connection to remote LLM service..."
    
    # Test the remote LLM service
    if curl -s -o /dev/null -w "%{http_code}" "http://100.79.227.126:1234/v1/models" | grep -q "200"; then
        log_success "Remote LLM service is accessible"
        
        # Test a simple request
        RESPONSE=$(curl -s -X POST "http://100.79.227.126:1234/v1/chat/completions" \
            -H "Content-Type: application/json" \
            -d '{
                "model": "qwen/qwen3-4b-thinking-2507",
                "messages": [{"role": "user", "content": "Hello"}],
                "max_tokens": 50
            }' | jq -r '.choices[0].message | if .content != "" then .content else .reasoning_content end' 2>/dev/null || echo "Test failed")
        
        if [[ -n "$RESPONSE" && "$RESPONSE" != "null" ]]; then
            log_success "Remote LLM test successful"
            echo "Sample response: $RESPONSE"
        else
            log_warning "Remote LLM test failed"
        fi
    else
        log_error "Remote LLM service is not accessible"
        log_error "Please check:"
        echo "1. Remote LLM service is running"
        echo "2. Network connectivity to http://100.79.227.126:1234"
        echo "3. Firewall settings"
        exit 1
    fi
}

# Build Docker images
build_docker_images() {
    log_info "Building Docker images on $REMOTE_HOST..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Build API Gateway image
        echo 'Building API Gateway image...'
        docker build -f Dockerfile.gateway.pi -t api-gateway:latest .
        
        # List built images
        docker images | grep -E '(api-gateway|nginx)'
    "
    
    log_success "Docker images built"
}

# Start Docker services
start_docker_services() {
    log_info "Starting Docker services..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Stop existing services if running
        docker-compose -f $DOCKER_COMPOSE_FILE down 2>/dev/null || true
        
        # Start services
        docker-compose -f $DOCKER_COMPOSE_FILE up -d
        
        # Wait for services to start
        echo 'Waiting for services to start...'
        sleep 30
        
        # Check service status
        docker-compose -f $DOCKER_COMPOSE_FILE ps
    "
    
    log_success "Docker services started"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Get the Pi's IP address
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    log_info "Testing API Gateway (port 4000)..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:4000/health" | grep -q "200"; then
        log_success "API Gateway is responding"
    else
        log_warning "API Gateway may not be ready yet"
    fi
    
    log_info "Testing Wiki.js (port 3004)..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:3004" | grep -q "200"; then
        log_success "Wiki.js is responding"
    else
        log_warning "Wiki.js may not be ready yet"
    fi
    
    log_success "Deployment verification completed"
}

# Test AI interaction
test_ai_interaction() {
    log_info "Testing AI interaction..."
    
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    # Test API Gateway
    log_info "Testing API Gateway with remote LLM..."
    RESPONSE=$(curl -s -X POST "http://$PI_IP:4000/chat" \
        -H "Content-Type: application/json" \
        -d '{
            "message": "Hello, can you help me with system administration?",
            "stream": false
        }' | jq -r '.response' 2>/dev/null || echo "API Gateway test failed")
    
    if [[ -n "$RESPONSE" && "$RESPONSE" != "null" ]]; then
        log_success "API Gateway interaction test successful"
        echo "Response: $RESPONSE"
    else
        log_warning "API Gateway interaction test failed"
    fi
}

# Show deployment summary
show_summary() {
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    echo
    log_success "🎉 Remote LLM Deployment completed successfully!"
    echo
    log_info "Access your AI System Administrator Agent:"
    echo "  🌐 API Gateway: http://$PI_IP:4000"
    echo "  📚 Wiki.js: http://$PI_IP:3004"
    echo "  📊 Health Check: http://$PI_IP:4000/health"
    echo "  📋 Status: http://$PI_IP:4000/status"
    echo "  🧠 Remote LLM: http://100.79.227.126:1234"
    echo
    log_info "Docker management commands:"
    echo "  📋 Check status: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE ps'"
    echo "  📝 View logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE logs -f'"
    echo "  🔄 Restart: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE restart'"
    echo "  🛑 Stop: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE down'"
    echo
    log_info "AI Interaction Examples:"
    echo "  🌐 Web Gateway: Open http://$PI_IP:4000 in your browser"
    echo "  🔌 API Gateway: curl -X POST http://$PI_IP:4000/chat -d '{\"message\": \"Hello\"}'"
    echo "  🧠 Direct LLM: curl -X POST http://100.79.227.126:1234/v1/chat/completions -d '{\"model\": \"qwen/qwen3-4b-thinking-2507\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}]}'"
    echo
    log_info "Resource Usage Benefits:"
    echo "  💾 Memory: ~384MB total (vs ~6GB with local models)"
    echo "  🚀 Startup: ~30 seconds (vs ~60 seconds with local models)"
    echo "  🔋 Power: Significantly reduced CPU usage"
    echo "  📡 Network: Uses remote LLM service for processing"
    echo
    log_info "Wiki.js Setup:"
    echo "  📚 Access: http://$PI_IP:3004"
    echo "  ⚙️  Initial setup required on first access"
    echo "  📝 Create admin account and configure site"
    echo
}

# Main deployment function
main() {
    log_info "Starting remote LLM deployment to $REMOTE_HOST..."
    
    check_local_directory
    test_ssh_connection
    check_docker_installation
    test_remote_llm
    setup_remote_directory
    pull_latest_code
    copy_deployment_files
    build_docker_images
    start_docker_services
    verify_deployment
    test_ai_interaction
    show_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Remote LLM Deployment Script for AI System Administrator Agent"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --test-only    Only test SSH connection and Docker"
        echo "  --build-only   Only build images (skip deployment)"
        echo "  --quick        Quick deployment (skip verification)"
        echo
        echo "Environment variables:"
        echo "  REMOTE_HOST    Remote hostname or IP (default: meatpi)"
        echo "  REMOTE_USER    Remote username (default: inggo)"
        echo
        echo "Services deployed:"
        echo "  🧠 Remote Qwen3-4B-Thinking - http://100.79.227.126:1234"
        echo "  🌐 API Gateway - Port 8080"
        echo "  📚 Wiki.js - Port 3004"
        echo
        echo "Benefits:"
        echo "  💾 Low memory usage (~384MB vs ~6GB)"
        echo "  🚀 Fast startup (~30s vs ~60s)"
        echo "  🔋 Reduced power consumption"
        echo "  🧠 Advanced reasoning capabilities"
        echo
        exit 0
        ;;
    --test-only)
        test_ssh_connection
        check_docker_installation
        test_remote_llm
        log_success "Environment test passed"
        exit 0
        ;;
    --build-only)
        check_local_directory
        test_ssh_connection
        check_docker_installation
        setup_remote_directory
        copy_deployment_files
        build_docker_images
        log_success "Docker images built successfully"
        exit 0
        ;;
    --quick)
        check_local_directory
        test_ssh_connection
        check_docker_installation
        test_remote_llm
        setup_remote_directory
        copy_deployment_files
        build_docker_images
        start_docker_services
        show_summary
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
