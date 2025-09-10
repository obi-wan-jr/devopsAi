#!/bin/bash

# Quick Test Script for AI System Administrator Agent and Website
# This script runs essential tests quickly

set -e

# Configuration
PROJECT_DIR="/Users/inggo/Documents/ai-sysadmin-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"
WEBSITE_PORT="3004"

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

# Test 1: Local Structure
test_local() {
    log_info "Testing local project structure..."
    
    local files=(
        "src/main.py"
        "src/agent/sysadmin_agent.py"
        "src/interfaces/web.py"
        "config/agent.yaml"
        "requirements.txt"
        "website/index.html"
        "website/css/style.css"
        "website/js/script.js"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$PROJECT_DIR/$file" ]]; then
            log_info "✓ $file"
        else
            log_error "✗ $file missing"
            return 1
        fi
    done
    
    log_success "Local structure OK"
}

# Test 2: Python Syntax
test_python() {
    log_info "Testing Python syntax..."
    
    local python_files=(
        "src/main.py"
        "src/agent/sysadmin_agent.py"
        "src/interfaces/web.py"
    )
    
    for file in "${python_files[@]}"; do
        if python3 -m py_compile "$PROJECT_DIR/$file" 2>/dev/null; then
            log_info "✓ $file syntax OK"
        else
            log_error "✗ $file syntax error"
            return 1
        fi
    done
    
    log_success "Python syntax OK"
}

# Test 3: Website Structure
test_website() {
    log_info "Testing website structure..."
    
    # Check HTML
    if grep -q "AI System Administrator Agent" "$PROJECT_DIR/website/index.html"; then
        log_info "✓ HTML content OK"
    else
        log_error "✗ HTML content missing"
        return 1
    fi
    
    # Check CSS
    if grep -q ":root" "$PROJECT_DIR/website/css/style.css"; then
        log_info "✓ CSS structure OK"
    else
        log_error "✗ CSS structure missing"
        return 1
    fi
    
    # Check JS
    if grep -q "DOMContentLoaded" "$PROJECT_DIR/website/js/script.js"; then
        log_info "✓ JavaScript structure OK"
    else
        log_error "✗ JavaScript structure missing"
        return 1
    fi
    
    log_success "Website structure OK"
}

# Test 4: Remote Connection
test_remote() {
    log_info "Testing remote connection..."
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" exit 2>/dev/null; then
        log_success "SSH connection OK"
    else
        log_error "SSH connection failed"
        return 1
    fi
}

# Test 5: Deploy Website
deploy_website() {
    log_info "Deploying website to $REMOTE_HOST..."
    
    # Copy website files
    rsync -avz --progress \
        "$PROJECT_DIR/website/" \
        "$REMOTE_USER@$REMOTE_HOST:/home/inggo/website/" 2>/dev/null
    
    # Setup nginx
    ssh "$REMOTE_USER@$REMOTE_HOST" "
        # Install nginx if needed
        if ! command -v nginx >/dev/null 2>&1; then
            sudo apt update -qq
            sudo apt install -y nginx -qq
        fi
        
        # Create nginx config
        sudo tee /etc/nginx/sites-available/ai-agent-wiki > /dev/null <<EOF
server {
    listen 3004;
    server_name _;
    root /home/inggo/website;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
        
        # Enable site
        sudo ln -sf /etc/nginx/sites-available/ai-agent-wiki /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
        
        # Restart nginx
        sudo nginx -t -q
        sudo systemctl restart nginx -q
        
        # Allow port
        sudo ufw allow 3004/tcp -q
    " 2>/dev/null
    
    log_success "Website deployed"
}

# Test 6: Website Accessibility
test_website_access() {
    log_info "Testing website accessibility..."
    
    # Get Pi IP
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'" 2>/dev/null)
    
    # Test website
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:3004" | grep -q "200"; then
        log_success "Website accessible at http://$PI_IP:3004"
    else
        log_error "Website not accessible"
        return 1
    fi
    
    # Test content
    if curl -s "http://$PI_IP:3004" | grep -q "AI System Administrator Agent"; then
        log_success "Website content OK"
    else
        log_error "Website content missing"
        return 1
    fi
}

# Main function
main() {
    log_info "Running quick tests..."
    echo
    
    test_local
    test_python
    test_website
    test_remote
    deploy_website
    test_website_access
    
    echo
    log_success "🎉 Quick tests completed successfully!"
    
    # Show results
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'" 2>/dev/null)
    
    echo
    log_info "Test Results:"
    echo "  ✅ Local project structure: OK"
    echo "  ✅ Python syntax: OK"
    echo "  ✅ Website structure: OK"
    echo "  ✅ Remote connection: OK"
    echo "  ✅ Website deployment: OK"
    echo "  ✅ Website accessibility: OK"
    echo
    log_info "Access your AI System Administrator Agent Wiki:"
    echo "  🌐 Website: http://$PI_IP:3004"
    echo "  📚 Documentation: Complete"
    echo "  🚀 Ready for AI agent deployment"
}

# Run main function
main "$@"
