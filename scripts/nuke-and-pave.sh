#!/bin/bash

# Nuke and Pave Cleanup Script for AI System Administrator Agent
# This script safely removes ONLY project-related Docker resources
# Does NOT affect other Docker containers or services on the system

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"
REMOTE_HOST="meatpi"
REMOTE_USER="inggo"

# Project-specific identifiers
PROJECT_CONTAINERS=(
    "ai-sysadmin-agent"
    "ollama-qwen25"
    "wiki-js"
    "llama-server"
)

PROJECT_IMAGES=(
    "ai-sysadmin-agent"
    "ollama-qwen25"
    "wiki-js"
    "llama-server"
    "ollama/ollama"
    "ghcr.io/requarks/wiki"
)

PROJECT_NETWORKS=(
    "ai-agent-network"
)

PROJECT_VOLUMES=(
    "ollama_data"
    "wiki_data"
    "wiki_logs"
)

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

# Show current Docker resources
show_current_resources() {
    log_info "Current Docker resources on $REMOTE_HOST:"
    
    echo
    log_info "Containers:"
    remote_exec "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
    
    echo
    log_info "Images:"
    remote_exec "docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}'"
    
    echo
    log_info "Networks:"
    remote_exec "docker network ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}'"
    
    echo
    log_info "Volumes:"
    remote_exec "docker volume ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Size}}'"
}

# Stop project containers
stop_project_containers() {
    log_info "Stopping project containers..."
    
    for container in "${PROJECT_CONTAINERS[@]}"; do
        if remote_exec "docker ps -q -f name=$container" | grep -q .; then
            log_info "Stopping container: $container"
            remote_exec "docker stop $container" || log_warning "Failed to stop $container"
        else
            log_info "Container $container is not running"
        fi
    done
    
    log_success "Project containers stopped"
}

# Remove project containers
remove_project_containers() {
    log_info "Removing project containers..."
    
    for container in "${PROJECT_CONTAINERS[@]}"; do
        if remote_exec "docker ps -aq -f name=$container" | grep -q .; then
            log_info "Removing container: $container"
            remote_exec "docker rm -f $container" || log_warning "Failed to remove $container"
        else
            log_info "Container $container does not exist"
        fi
    done
    
    log_success "Project containers removed"
}

# Remove project images
remove_project_images() {
    log_info "Removing project images..."
    
    for image in "${PROJECT_IMAGES[@]}"; do
        if remote_exec "docker images -q $image" | grep -q .; then
            log_info "Removing image: $image"
            remote_exec "docker rmi -f $image" || log_warning "Failed to remove $image"
        else
            log_info "Image $image does not exist"
        fi
    done
    
    # Remove any dangling images created during builds
    log_info "Removing dangling images..."
    remote_exec "docker image prune -f" || log_warning "No dangling images to remove"
    
    log_success "Project images removed"
}

# Remove project networks
remove_project_networks() {
    log_info "Removing project networks..."
    
    for network in "${PROJECT_NETWORKS[@]}"; do
        if remote_exec "docker network ls -q -f name=$network" | grep -q .; then
            log_info "Removing network: $network"
            remote_exec "docker network rm $network" || log_warning "Failed to remove $network"
        else
            log_info "Network $network does not exist"
        fi
    done
    
    log_success "Project networks removed"
}

# Remove project volumes
remove_project_volumes() {
    log_info "Removing project volumes..."
    
    for volume in "${PROJECT_VOLUMES[@]}"; do
        if remote_exec "docker volume ls -q -f name=$volume" | grep -q .; then
            log_info "Removing volume: $volume"
            remote_exec "docker volume rm $volume" || log_warning "Failed to remove $volume"
        else
            log_info "Volume $volume does not exist"
        fi
    done
    
    log_success "Project volumes removed"
}

# Clean up project directory
cleanup_project_directory() {
    log_info "Cleaning up project directory..."
    
    # Remove Docker Compose files
    remote_exec "rm -f docker-compose.yml docker-compose.pi.yml docker-compose.meatpi.yml"
    
    # Remove Dockerfiles
    remote_exec "rm -f Dockerfile Dockerfile.pi Dockerfile.llama Dockerfile.llama.pi Dockerfile.ollama.pi"
    
    # Remove logs directory
    remote_exec "rm -rf logs/"
    
    # Remove any temporary files
    remote_exec "rm -f .env .env.local"
    
    log_success "Project directory cleaned"
}

# Verify cleanup
verify_cleanup() {
    log_info "Verifying cleanup..."
    
    # Check that no project containers exist
    local remaining_containers=$(remote_exec "docker ps -aq -f name=ai-sysadmin-agent -f name=ollama-qwen25 -f name=wiki-js -f name=llama-server" | wc -l)
    if [ "$remaining_containers" -gt 0 ]; then
        log_warning "Some project containers still exist"
        remote_exec "docker ps -a -f name=ai-sysadmin-agent -f name=ollama-qwen25 -f name=wiki-js -f name=llama-server"
    else
        log_success "All project containers removed"
    fi
    
    # Check that no project images exist
    local remaining_images=$(remote_exec "docker images -q ai-sysadmin-agent ollama-qwen25 wiki-js llama-server ollama/ollama ghcr.io/requarks/wiki" | wc -l)
    if [ "$remaining_images" -gt 0 ]; then
        log_warning "Some project images still exist"
        remote_exec "docker images ai-sysadmin-agent ollama-qwen25 wiki-js llama-server ollama/ollama ghcr.io/requarks/wiki"
    else
        log_success "All project images removed"
    fi
    
    # Check that no project networks exist
    local remaining_networks=$(remote_exec "docker network ls -q -f name=ai-agent-network" | wc -l)
    if [ "$remaining_networks" -gt 0 ]; then
        log_warning "Project network still exists"
        remote_exec "docker network ls -f name=ai-agent-network"
    else
        log_success "Project network removed"
    fi
    
    # Check that no project volumes exist
    local remaining_volumes=$(remote_exec "docker volume ls -q -f name=ollama_data -f name=wiki_data -f name=wiki_logs" | wc -l)
    if [ "$remaining_volumes" -gt 0 ]; then
        log_warning "Some project volumes still exist"
        remote_exec "docker volume ls -f name=ollama_data -f name=wiki_data -f name=wiki_logs"
    else
        log_success "All project volumes removed"
    fi
}

# Show other Docker resources (for safety verification)
show_other_resources() {
    log_info "Other Docker resources on the system (should remain untouched):"
    
    echo
    log_info "Other containers:"
    remote_exec "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | grep -v -E '(ai-sysadmin-agent|ollama-qwen25|wiki-js|llama-server)' || echo 'No other containers found'"
    
    echo
    log_info "Other images:"
    remote_exec "docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}' | grep -v -E '(ai-sysadmin-agent|ollama-qwen25|wiki-js|llama-server|ollama/ollama|ghcr.io/requarks/wiki)' || echo 'No other images found'"
    
    echo
    log_info "Other networks:"
    remote_exec "docker network ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}' | grep -v -E '(ai-agent-network)' || echo 'No other networks found'"
    
    echo
    log_info "Other volumes:"
    remote_exec "docker volume ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Size}}' | grep -v -E '(ollama_data|wiki_data|wiki_logs)' || echo 'No other volumes found'"
}

# Main cleanup function
main_cleanup() {
    log_info "Starting nuke and pave cleanup for AI System Administrator Agent project..."
    
    # Show current state
    show_current_resources
    
    # Confirm with user
    echo
    log_warning "This will remove ALL project-related Docker resources:"
    echo "  - Containers: ${PROJECT_CONTAINERS[*]}"
    echo "  - Images: ${PROJECT_IMAGES[*]}"
    echo "  - Networks: ${PROJECT_NETWORKS[*]}"
    echo "  - Volumes: ${PROJECT_VOLUMES[*]}"
    echo
    log_warning "Other Docker resources will remain untouched."
    echo
    read -p "Continue with cleanup? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    # Perform cleanup steps
    stop_project_containers
    remove_project_containers
    remove_project_images
    remove_project_networks
    remove_project_volumes
    cleanup_project_directory
    
    # Verify cleanup
    verify_cleanup
    
    # Show remaining resources
    show_other_resources
    
    log_success "🎉 Nuke and pave cleanup completed successfully!"
    echo
    log_info "All project-related Docker resources have been removed."
    log_info "Other Docker containers and services remain untouched."
    echo
    log_info "Next steps:"
    echo "  1. Pull latest code: git pull origin main"
    echo "  2. Deploy fresh: ./scripts/deploy-meatpi.sh"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Nuke and Pave Cleanup Script for AI System Administrator Agent"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --dry-run      Show what would be removed without actually removing"
        echo "  --verify       Only verify current state (no cleanup)"
        echo
        echo "This script safely removes ONLY project-related Docker resources:"
        echo "  - Containers: ai-sysadmin-agent, ollama-qwen25, wiki-js, llama-server"
        echo "  - Images: project images and dependencies"
        echo "  - Networks: ai-agent-network"
        echo "  - Volumes: ollama_data, wiki_data, wiki_logs"
        echo
        echo "Other Docker containers and services will remain untouched."
        exit 0
        ;;
    --dry-run)
        log_info "DRY RUN - Showing what would be removed:"
        show_current_resources
        echo
        log_info "Would remove:"
        echo "  Containers: ${PROJECT_CONTAINERS[*]}"
        echo "  Images: ${PROJECT_IMAGES[*]}"
        echo "  Networks: ${PROJECT_NETWORKS[*]}"
        echo "  Volumes: ${PROJECT_VOLUMES[*]}"
        exit 0
        ;;
    --verify)
        show_current_resources
        show_other_resources
        exit 0
        ;;
    "")
        main_cleanup
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
