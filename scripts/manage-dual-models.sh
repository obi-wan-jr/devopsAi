#!/bin/bash

# Management Script for Dual-Model AI System Administrator Agent on Raspberry Pi 5 "meatpi"
# Manages Gemma 2 + DeepSeek-R1 Distill + API Gateway + Wiki.js services

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"
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

# Execute command on remote host
remote_exec() {
    ssh "$REMOTE_USER@$REMOTE_HOST" "cd $PROJECT_DIR && $1"
}

# Show status
show_status() {
    log_info "Checking Docker service status..."
    
    remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE ps"
    
    echo
    log_info "Container resource usage:"
    remote_exec "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' | grep -E '(ollama-gemma2|ollama-deepseek|api-gateway|wiki-js)' || echo 'No project containers running'"
    
    echo
    log_info "Docker system info:"
    remote_exec "docker system df"
}

# Show logs
show_logs() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        log_info "Showing logs for $service..."
        remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE logs -f $service"
    else
        log_info "Showing logs for all services..."
        remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
    fi
}

# Restart services
restart_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        log_info "Restarting $service..."
        remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE restart $service"
    else
        log_info "Restarting all services..."
        remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE restart"
    fi
    
    log_success "Services restarted"
}

# Stop services
stop_services() {
    log_info "Stopping all services..."
    remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE down"
    log_success "Services stopped"
}

# Start services
start_services() {
    log_info "Starting all services..."
    remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE up -d"
    
    # Wait for services to start
    sleep 20
    
    log_success "Services started"
    show_status
}

# Update and rebuild
update_services() {
    log_info "Updating services..."
    
    # Pull latest code
    log_info "Pulling latest code..."
    git pull origin main || log_warning "Git pull failed or no remote configured"
    
    # Copy updated files to remote
    log_info "Copying updated files to $REMOTE_HOST..."
    rsync -avz --progress \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.env' \
        --exclude='models/' \
        --exclude='logs/' \
        src/ \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/src/"
    
    rsync -avz --progress \
        config/ \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/config/"
    
    rsync -avz --progress \
        docker-compose.dual-models.yml \
        Dockerfile.gateway.pi \
        "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR/"
    
    # Rebuild and restart
    log_info "Rebuilding Docker images..."
    remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE build --no-cache"
    
    log_info "Restarting services with new images..."
    remote_exec "docker-compose -f $DOCKER_COMPOSE_FILE up -d --force-recreate"
    
    log_success "Services updated"
    show_status
}

# Clean up (nuke and pave)
cleanup() {
    log_warning "This will remove all project containers, images, and volumes. Continue? (y/N)"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Running nuke and pave cleanup..."
        remote_exec "./scripts/nuke-and-pave.sh"
        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Get Pi IP
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    # Check Gemma 2 service
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:11434/api/tags" | grep -q "200"; then
        log_success "✅ Gemma 2 service healthy"
    else
        log_error "❌ Gemma 2 service unhealthy"
    fi
    
    # Check DeepSeek-R1 service
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:11435/api/tags" | grep -q "200"; then
        log_success "✅ DeepSeek-R1 service healthy"
    else
        log_error "❌ DeepSeek-R1 service unhealthy"
    fi
    
    # Check API Gateway
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8080/health" | grep -q "200"; then
        log_success "✅ API Gateway healthy"
    else
        log_error "❌ API Gateway unhealthy"
    fi
    
    # Check Wiki.js
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:3004" | grep -q "200"; then
        log_success "✅ Wiki.js healthy"
    else
        log_error "❌ Wiki.js unhealthy"
    fi
}

# Test AI interaction
test_ai() {
    log_info "Testing AI interaction..."
    
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    # Test API Gateway with auto selection
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
    
    # Test specific model selection
    log_info "Testing specific model selection (Gemma 2)..."
    RESPONSE2=$(curl -s -X POST "http://$PI_IP:8080/chat/gemma2" \
        -H "Content-Type: application/json" \
        -d '{
            "message": "Show me the current system status",
            "stream": false
        }' | jq -r '.response' 2>/dev/null || echo "Gemma 2 test failed")
    
    if [[ -n "$RESPONSE2" && "$RESPONSE2" != "null" ]]; then
        log_success "Gemma 2 interaction test successful"
    else
        log_warning "Gemma 2 interaction test failed"
    fi
}

# Show access URLs
show_urls() {
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    echo
    log_info "Access URLs for $REMOTE_HOST ($PI_IP):"
    echo "  🧠 Gemma 2 API: http://$PI_IP:11434"
    echo "  🧠 DeepSeek-R1 API: http://$PI_IP:11435"
    echo "  🌐 API Gateway: http://$PI_IP:8080"
    echo "  📚 Wiki.js: http://$PI_IP:3004"
    echo "  📊 Health Check: http://$PI_IP:8080/health"
    echo "  📋 Status: http://$PI_IP:8080/status"
    echo "  📖 Models: http://$PI_IP:8080/models"
    echo
}

# Show model comparison
show_models() {
    PI_IP=$(ssh "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    log_info "Available Models and Their Strengths:"
    echo
    echo "🧠 Gemma 2 (2B parameters) - Port 11434"
    echo "   Best for: General tasks, Code generation, System monitoring, Troubleshooting"
    echo "   Use when: You need quick, reliable responses for common system admin tasks"
    echo "   Direct API: curl -X POST http://$PI_IP:11434/api/generate -d '{\"model\": \"gemma2:2b\", \"prompt\": \"Your question\"}'"
    echo
    echo "🧠 DeepSeek-R1 Distill (1.5B parameters) - Port 11435"
    echo "   Best for: Complex reasoning, Problem analysis, Decision making, Root cause analysis"
    echo "   Use when: You need deep analysis or complex problem-solving"
    echo "   Direct API: curl -X POST http://$PI_IP:11435/api/generate -d '{\"model\": \"deepseek-r1-distill:1.5b\", \"prompt\": \"Your question\"}'"
    echo
    echo "🌐 API Gateway - Port 8080"
    echo "   Auto-selects the best model based on your query"
    echo "   Gateway API: curl -X POST http://$PI_IP:8080/chat -d '{\"message\": \"Your question\"}'"
    echo "   Specific model: curl -X POST http://$PI_IP:8080/chat/gemma2 -d '{\"message\": \"Your question\"}'"
    echo
}

# Show help
show_help() {
    echo "Management Script for Dual-Model AI System Administrator Agent"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  status [service]     Show service status and resource usage"
    echo "  logs [service]       Show logs (optionally for specific service)"
    echo "  start                Start all services"
    echo "  stop                 Stop all services"
    echo "  restart [service]    Restart services (optionally specific service)"
    echo "  update               Update and rebuild services"
    echo "  cleanup              Remove all containers, images, and volumes"
    echo "  health               Perform health check"
    echo "  test                 Test AI interaction"
    echo "  urls                 Show access URLs"
    echo "  models               Show model comparison and usage"
    echo "  help                 Show this help message"
    echo
    echo "Services:"
    echo "  ollama-gemma2        Gemma 2 model service"
    echo "  ollama-deepseek      DeepSeek-R1 Distill model service"
    echo "  api-gateway          API Gateway for model routing"
    echo "  wiki                 Wiki.js documentation service"
    echo
    echo "Examples:"
    echo "  $0 status                    # Show all services status"
    echo "  $0 logs api-gateway          # Show logs for API Gateway"
    echo "  $0 restart ollama-gemma2     # Restart Gemma 2 service"
    echo "  $0 health                    # Check all endpoints"
    echo "  $0 test                      # Test AI interaction"
    echo "  $0 urls                      # Show access URLs"
    echo "  $0 models                    # Show model comparison"
}

# Main function
main() {
    case "${1:-help}" in
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services "$2"
            ;;
        update)
            update_services
            ;;
        cleanup)
            cleanup
            ;;
        health)
            health_check
            ;;
        test)
            test_ai
            ;;
        urls)
            show_urls
            ;;
        models)
            show_models
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
