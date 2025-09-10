#!/bin/bash

# Dual-Model Deployment Script for AI System Administrator Agent on Raspberry Pi 5 "meatpi"
# Features: Gemma 2 (2B) + DeepSeek-R1 Distill (1.5B) + API Gateway + Wiki.js
# Ports: Gemma 2 (11434), DeepSeek-R1 (11435), Gateway (8080), Wiki (3004)

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"
LOCAL_PROJECT_DIR="/Users/inggo/Documents/ai-sysadmin-agent"
DOCKER_COMPOSE_FILE="docker-compose.dual-models.yml"

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
    if [[ ! -f "docker-compose.dual-models.yml" ]] || [[ ! -f "Dockerfile.gateway.pi" ]]; then
        log_error "Please run this script from the project root directory"
        log_error "Required files: docker-compose.dual-models.yml, Dockerfile.gateway.pi"
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
        mkdir -p $PROJECT_DIR/{models,logs,config,data/{gemma2,deepseek,wiki}}
        mkdir -p $PROJECT_DIR/logs/wiki
        chmod 755 $PROJECT_DIR/data/gemma2
        chmod 755 $PROJECT_DIR/data/deepseek
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
        docker-compose.dual-models.yml \
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

# Download models
download_models() {
    log_info "Setting up Gemma 2 and DeepSeek-R1 Distill models..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Start Ollama services temporarily to pull models
        echo 'Starting Ollama services to download models...'
        
        # Start Gemma 2 service
        docker run -d --name temp-gemma2 \
            -v gemma2_data:/root/.ollama \
            -p 11434:11434 \
            ollama/ollama:latest
        
        # Start DeepSeek service  
        docker run -d --name temp-deepseek \
            -v deepseek_data:/root/.ollama \
            -p 11435:11434 \
            ollama/ollama:latest
        
        # Wait for services to start
        sleep 30
        
        # Pull Gemma 2 model
        echo 'Pulling Gemma 2 (2B) model...'
        docker exec temp-gemma2 ollama pull gemma2:2b || {
            echo 'Failed to pull Gemma 2, trying alternative...'
            docker exec temp-gemma2 ollama pull gemma2:latest
        }
        
        # Pull DeepSeek-R1 Distill model
        echo 'Pulling DeepSeek-R1 Distill (1.5B) model...'
        docker exec temp-deepseek ollama pull deepseek-r1-distill:1.5b || {
            echo 'Failed to pull DeepSeek-R1 Distill, trying alternative...'
            docker exec temp-deepseek ollama pull deepseek-r1:latest
        }
        
        # Stop temporary containers
        docker stop temp-gemma2 temp-deepseek
        docker rm temp-gemma2 temp-deepseek
        
        echo 'Models setup completed'
    "
    
    log_success "Models downloaded"
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
        docker images | grep -E '(api-gateway|ollama|wiki)'
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
        sleep 45
        
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
    
    log_info "Testing Gemma 2 service (port 11434)..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:11434/api/tags" | grep -q "200"; then
        log_success "Gemma 2 service is responding"
    else
        log_warning "Gemma 2 service may not be ready yet"
    fi
    
    log_info "Testing DeepSeek-R1 service (port 11435)..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:11435/api/tags" | grep -q "200"; then
        log_success "DeepSeek-R1 service is responding"
    else
        log_warning "DeepSeek-R1 service may not be ready yet"
    fi
    
    log_info "Testing API Gateway (port 8080)..."
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8080/health" | grep -q "200"; then
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
    log_info "Testing API Gateway with auto model selection..."
    RESPONSE=$(curl -s -X POST "http://$PI_IP:8080/chat" \
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
    log_success "🎉 Dual-Model Deployment completed successfully!"
    echo
    log_info "Access your AI System Administrator Agent:"
    echo "  🧠 Gemma 2 API: http://$PI_IP:11434"
    echo "  🧠 DeepSeek-R1 API: http://$PI_IP:11435"
    echo "  🌐 API Gateway: http://$PI_IP:8080"
    echo "  📚 Wiki.js: http://$PI_IP:3004"
    echo "  📊 Health Check: http://$PI_IP:8080/health"
    echo "  📋 Status: http://$PI_IP:8080/status"
    echo
    log_info "Docker management commands:"
    echo "  📋 Check status: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE ps'"
    echo "  📝 View logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE logs -f'"
    echo "  🔄 Restart: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE restart'"
    echo "  🛑 Stop: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && docker-compose -f $DOCKER_COMPOSE_FILE down'"
    echo "  🗑️  Cleanup: ssh $REMOTE_USER@$REMOTE_HOST 'cd $PROJECT_DIR && ./scripts/nuke-and-pave.sh'"
    echo
    log_info "AI Interaction Examples:"
    echo "  🌐 Web Gateway: Open http://$PI_IP:8080 in your browser"
    echo "  🔌 API Gateway: curl -X POST http://$PI_IP:8080/chat -d '{\"message\": \"Hello\"}'"
    echo "  🧠 Gemma 2 Direct: curl -X POST http://$PI_IP:11434/api/generate -d '{\"model\": \"gemma2:2b\", \"prompt\": \"Hello\"}'"
    echo "  🧠 DeepSeek Direct: curl -X POST http://$PI_IP:11435/api/generate -d '{\"model\": \"deepseek-r1-distill:1.5b\", \"prompt\": \"Hello\"}'"
    echo "  🎯 Specific Model: curl -X POST http://$PI_IP:8080/chat/gemma2 -d '{\"message\": \"Hello\"}'"
    echo
    log_info "Wiki.js Setup:"
    echo "  📚 Access: http://$PI_IP:3004"
    echo "  ⚙️  Initial setup required on first access"
    echo "  📝 Create admin account and configure site"
    echo
}

# Main deployment function
main() {
    log_info "Starting dual-model deployment to $REMOTE_HOST..."
    
    check_local_directory
    test_ssh_connection
    check_docker_installation
    setup_remote_directory
    pull_latest_code
    copy_deployment_files
    download_models
    build_docker_images
    start_docker_services
    verify_deployment
    test_ai_interaction
    show_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Dual-Model Deployment Script for AI System Administrator Agent"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --test-only    Only test SSH connection and Docker"
        echo "  --build-only   Only build images (skip deployment)"
        echo "  --no-models    Skip model download (use existing)"
        echo "  --quick        Quick deployment (skip verification)"
        echo
        echo "Environment variables:"
        echo "  REMOTE_HOST    Remote hostname or IP (default: meatpi)"
        echo "  REMOTE_USER    Remote username (default: inggo)"
        echo
        echo "Services deployed:"
        echo "  🧠 Gemma 2 (2B parameters) - Port 11434"
        echo "  🧠 DeepSeek-R1 Distill (1.5B parameters) - Port 11435"
        echo "  🌐 API Gateway - Port 8080"
        echo "  📚 Wiki.js - Port 3004"
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
        copy_deployment_files
        build_docker_images
        log_success "Docker images built successfully"
        exit 0
        ;;
    --no-models)
        check_local_directory
        test_ssh_connection
        check_docker_installation
        setup_remote_directory
        pull_latest_code
        copy_deployment_files
        build_docker_images
        start_docker_services
        verify_deployment
        show_summary
        exit 0
        ;;
    --quick)
        check_local_directory
        test_ssh_connection
        check_docker_installation
        setup_remote_directory
        copy_deployment_files
        download_models
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
