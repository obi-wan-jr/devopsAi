#!/bin/bash

# Deployment Script - Deploy AI System Administrator Agent to Raspberry Pi
# This script handles the complete deployment process

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"  # Change this to your Pi's hostname or IP
REMOTE_USER="inggo"
LOCAL_PROJECT_DIR="/Users/inggo/Documents/ai-sysadmin-agent"

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
    if [[ ! -f "requirements.txt" ]] || [[ ! -d "src" ]]; then
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

# Create remote directory structure
setup_remote_directory() {
    log_info "Setting up remote directory structure..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        mkdir -p $PROJECT_DIR/{src,config,scripts,models,logs,tests}
        mkdir -p $PROJECT_DIR/src/{agent,interfaces,security,utils}
    "
    
    log_success "Remote directory structure created"
}

# Copy project files
copy_project_files() {
    log_info "Copying project files to $REMOTE_HOST..."
    
    # Copy main project files
    rsync -avz --progress \
        --exclude='.git' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.env' \
        --exclude='models/' \
        --exclude='logs/' \
        --exclude='ai-agent-env/' \
        "$LOCAL_PROJECT_DIR/" "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/"
    
    log_success "Project files copied"
}

# Run installation on remote host
run_remote_installation() {
    log_info "Running installation on remote host..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        chmod +x scripts/*.sh
        
        # Run installation
        ./scripts/install.sh
        
        # Run tests
        ./scripts/test_agent.sh
    "
    
    log_success "Remote installation completed"
}

# Start the agent service
start_agent_service() {
    log_info "Starting agent service..."
    
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        cd $PROJECT_DIR
        
        # Stop existing service if running
        sudo systemctl stop ai-sysadmin-agent 2>/dev/null || true
        
        # Start the service
        sudo systemctl start ai-sysadmin-agent
        
        # Check status
        sleep 5
        sudo systemctl status ai-sysadmin-agent --no-pager
    "
    
    log_success "Agent service started"
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
    
    log_success "Deployment verification completed"
}

# Show deployment summary
show_summary() {
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    echo
    log_success "🎉 Deployment completed successfully!"
    echo
    log_info "Access your AI System Administrator Agent:"
    echo "  🌐 Web Interface: http://$PI_IP:8080"
    echo "  🔌 API Endpoint: http://$PI_IP:8081"
    echo "  📊 Health Check: http://$PI_IP:8080/health"
    echo
    log_info "Useful commands:"
    echo "  📋 Check status: ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl status ai-sysadmin-agent'"
    echo "  📝 View logs: ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -u ai-sysadmin-agent -f'"
    echo "  🔄 Restart: ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl restart ai-sysadmin-agent'"
    echo "  🛑 Stop: ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl stop ai-sysadmin-agent'"
    echo
    log_info "Project files are located at: $PROJECT_DIR"
    echo
}

# Main deployment function
main() {
    log_info "Starting deployment to $REMOTE_HOST..."
    
    check_local_directory
    test_ssh_connection
    setup_remote_directory
    copy_project_files
    run_remote_installation
    start_agent_service
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
        echo "  --test-only    Only test SSH connection"
        echo "  --copy-only    Only copy files (skip installation)"
        echo
        echo "Environment variables:"
        echo "  REMOTE_HOST    Remote hostname or IP (default: meatpi)"
        echo "  REMOTE_USER    Remote username (default: inggo)"
        echo
        exit 0
        ;;
    --test-only)
        test_ssh_connection
        log_success "SSH connection test passed"
        exit 0
        ;;
    --copy-only)
        check_local_directory
        test_ssh_connection
        setup_remote_directory
        copy_project_files
        log_success "Files copied successfully"
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
