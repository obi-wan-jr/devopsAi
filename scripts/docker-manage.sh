#!/bin/bash

# Docker Management Script for AI System Administrator Agent
# This script provides easy management of Docker containers on meatpi

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"

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
    
    remote_exec "docker-compose ps"
    
    echo
    log_info "Container resource usage:"
    remote_exec "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}'"
    
    echo
    log_info "Docker system info:"
    remote_exec "docker system df"
}

# Show logs
show_logs() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        log_info "Showing logs for $service..."
        remote_exec "docker-compose logs -f $service"
    else
        log_info "Showing logs for all services..."
        remote_exec "docker-compose logs -f"
    fi
}

# Restart services
restart_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        log_info "Restarting $service..."
        remote_exec "docker-compose restart $service"
    else
        log_info "Restarting all services..."
        remote_exec "docker-compose restart"
    fi
    
    log_success "Services restarted"
}

# Stop services
stop_services() {
    log_info "Stopping all services..."
    remote_exec "docker-compose down"
    log_success "Services stopped"
}

# Start services
start_services() {
    log_info "Starting all services..."
    remote_exec "docker-compose up -d"
    
    # Wait for services to start
    sleep 10
    
    log_success "Services started"
    show_status
}

# Update and rebuild
update_services() {
    log_info "Updating services..."
    
    # Pull latest code
    log_info "Pulling latest code..."
    git pull origin main
    
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
    
    # Rebuild and restart
    log_info "Rebuilding Docker images..."
    remote_exec "docker-compose build --no-cache"
    
    log_info "Restarting services with new images..."
    remote_exec "docker-compose up -d --force-recreate"
    
    log_success "Services updated"
    show_status
}

# Clean up
cleanup() {
    log_warning "This will remove all containers, images, and volumes. Continue? (y/N)"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up Docker resources..."
        remote_exec "docker-compose down -v --rmi all"
        remote_exec "docker system prune -af"
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
    
    # Check web interface
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8080/health" | grep -q "200"; then
        log_success "✅ Web interface healthy"
    else
        log_error "❌ Web interface unhealthy"
    fi
    
    # Check API
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8081/api/status" | grep -q "200"; then
        log_success "✅ API healthy"
    else
        log_error "❌ API unhealthy"
    fi
    
    # Check LLM server
    if curl -s -o /dev/null -w "%{http_code}" "http://$PI_IP:8082/health" | grep -q "200"; then
        log_success "✅ LLM server healthy"
    else
        log_error "❌ LLM server unhealthy"
    fi
}

# Show help
show_help() {
    echo "Docker Management Script for AI System Administrator Agent"
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
    echo "  help                 Show this help message"
    echo
    echo "Services:"
    echo "  ai-sysadmin-agent    Main application container"
    echo "  llama-server         LLM server container"
    echo
    echo "Examples:"
    echo "  $0 status                    # Show all services status"
    echo "  $0 logs ai-sysadmin-agent   # Show logs for main app"
    echo "  $0 restart llama-server     # Restart LLM server"
    echo "  $0 health                   # Check all endpoints"
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
