# Docker Deployment Guide

This guide covers deploying the AI System Administrator Agent using Docker on Raspberry Pi 5.

## 🐳 Docker Architecture

The Docker deployment consists of two main containers:

1. **ai-sysadmin-agent**: Main application with AutoGen and web interfaces
2. **llama-server**: Dedicated LLM server running llama.cpp

## 📋 Prerequisites

### On Raspberry Pi 5 (meatpi)
- Docker Engine installed
- Docker Compose plugin installed
- At least 8GB RAM (4GB minimum)
- 32GB+ storage space
- Network connectivity

### On Development Machine
- SSH access to meatpi
- rsync installed
- curl for health checks

## 🚀 Quick Deployment

### Automated Deployment
```bash
# From your development machine
cd /Users/inggo/Documents/ai-sysadmin-agent
./scripts/docker-deploy.sh
```

This script will:
1. Test SSH connection to meatpi
2. Install Docker if needed
3. Copy all necessary files
4. Download the Qwen2 1.5B model
5. Build optimized Docker images
6. Start the services
7. Verify deployment

### Manual Deployment

1. **SSH into meatpi**:
   ```bash
   ssh inggo@meatpi
   ```

2. **Create project directory**:
   ```bash
   mkdir -p /home/inggo/ai-agent
   cd /home/inggo/ai-agent
   ```

3. **Copy files from development machine**:
   ```bash
   # From development machine
   rsync -avz --progress \
     --exclude='__pycache__' \
     --exclude='*.pyc' \
     --exclude='models/' \
     --exclude='logs/' \
     /Users/inggo/Documents/ai-sysadmin-agent/ \
     inggo@meatpi:/home/inggo/ai-agent/
   ```

4. **Download the model**:
   ```bash
   # On meatpi
   cd /home/inggo/ai-agent
   mkdir -p models
   
   # Download using Docker
   docker run --rm -v $(pwd)/models:/models \
     huggingface/hub-download:latest \
     --repo-id Qwen/Qwen2-1.5B-GGUF \
     --filename qwen2-1.5b-q4_k_m.gguf \
     --local-dir /models
   ```

5. **Build and start services**:
   ```bash
   # Build images
   docker-compose -f docker-compose.pi.yml build
   
   # Start services
   docker-compose -f docker-compose.pi.yml up -d
   ```

## 🔧 Configuration

### Docker Compose Files

- **`docker-compose.yml`**: Standard configuration
- **`docker-compose.pi.yml`**: Raspberry Pi 5 optimized

### Key Optimizations for Pi 5

```yaml
# Resource limits optimized for Pi 5
deploy:
  resources:
    limits:
      memory: 2G      # Main app
      cpus: '2.0'
    reservations:
      memory: 1G
      cpus: '1.0'
```

### Environment Variables

```bash
# Main application
MODEL_PATH=/app/models/qwen2-1.5b-q4_k_m.gguf
LLAMA_SERVER_URL=http://llama-server:8082
LOG_LEVEL=INFO
WEB_HOST=0.0.0.0
WEB_PORT=8080
API_PORT=8081

# LLM Server
N_THREADS=4
N_CTX=2048
BATCH_SIZE=512
```

## 🛠️ Management Commands

### Using the Management Script

```bash
# From development machine
./scripts/docker-manage.sh [command] [options]
```

**Available Commands:**
- `status` - Show service status and resource usage
- `logs [service]` - Show logs (optionally for specific service)
- `start` - Start all services
- `stop` - Stop all services
- `restart [service]` - Restart services
- `update` - Update and rebuild services
- `cleanup` - Remove all containers and images
- `health` - Perform health check

**Examples:**
```bash
# Check status
./scripts/docker-manage.sh status

# View logs
./scripts/docker-manage.sh logs ai-sysadmin-agent

# Restart LLM server
./scripts/docker-manage.sh restart llama-server

# Health check
./scripts/docker-manage.sh health
```

### Direct Docker Commands

```bash
# SSH into meatpi first
ssh inggo@meatpi
cd /home/inggo/ai-agent

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d

# Rebuild images
docker-compose build --no-cache

# Clean up
docker-compose down -v --rmi all
docker system prune -af
```

## 📊 Monitoring

### Health Checks

The containers include built-in health checks:

```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Manual health check
curl http://meatpi-ip:8080/health
curl http://meatpi-ip:8081/api/status
curl http://meatpi-ip:8082/health
```

### Resource Monitoring

```bash
# Container resource usage
docker stats --no-stream

# System resource usage
htop
free -h
df -h
```

### Log Monitoring

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ai-sysadmin-agent
docker-compose logs -f llama-server

# With timestamps
docker-compose logs -f -t
```

## 🔒 Security

### Container Security

- **Non-root execution**: All containers run as non-root user
- **Read-only filesystem**: Model files mounted read-only
- **Limited capabilities**: Dropped unnecessary capabilities
- **Network isolation**: Services communicate via internal network

### Host Security

```bash
# Firewall configuration
sudo ufw allow 8080/tcp  # Web interface
sudo ufw allow 8081/tcp  # API
sudo ufw allow 8082/tcp  # LLM server
sudo ufw enable

# SSH security
sudo ufw allow ssh
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
# Check logs
docker-compose logs ai-sysadmin-agent

# Check resource usage
docker stats

# Check disk space
df -h
```

#### 2. Model Loading Errors
```bash
# Verify model file
ls -la /home/inggo/ai-agent/models/

# Check model file integrity
file /home/inggo/ai-agent/models/qwen2-1.5b-q4_k_m.gguf

# Re-download model
docker run --rm -v $(pwd)/models:/models \
  huggingface/hub-download:latest \
  --repo-id Qwen/Qwen2-1.5B-GGUF \
  --filename qwen2-1.5b-q4_k_m.gguf \
  --local-dir /models
```

#### 3. High Memory Usage
```bash
# Check memory usage
free -h
docker stats

# Reduce resource limits in docker-compose.pi.yml
# Restart services
docker-compose restart
```

#### 4. Slow Performance
```bash
# Check CPU usage
htop
docker stats

# Optimize llama.cpp parameters
# Edit docker-compose.pi.yml environment variables
```

### Performance Optimization

#### 1. Model Optimization
```yaml
# In docker-compose.pi.yml
environment:
  - N_THREADS=4        # Match CPU cores
  - N_CTX=1024         # Reduce context length
  - BATCH_SIZE=256     # Reduce batch size
```

#### 2. Resource Limits
```yaml
# Adjust based on available resources
deploy:
  resources:
    limits:
      memory: 1.5G     # Reduce if needed
      cpus: '1.5'
```

#### 3. Storage Optimization
```bash
# Use SSD storage if available
# Enable swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🔄 Updates and Maintenance

### Updating the Application

```bash
# From development machine
./scripts/docker-manage.sh update
```

This will:
1. Pull latest code
2. Copy updated files to meatpi
3. Rebuild Docker images
4. Restart services

### Regular Maintenance

```bash
# Weekly cleanup
./scripts/docker-manage.sh cleanup

# Check for updates
docker-compose pull

# Monitor logs
./scripts/docker-manage.sh logs
```

### Backup and Restore

```bash
# Backup configuration and models
tar -czf ai-agent-backup-$(date +%Y%m%d).tar.gz \
  /home/inggo/ai-agent/{config,models}

# Restore from backup
tar -xzf ai-agent-backup-YYYYMMDD.tar.gz -C /
```

## 📈 Scaling

### Horizontal Scaling

For multiple Pi devices:

```bash
# Deploy to multiple hosts
for host in meatpi pi2 pi3; do
  REMOTE_HOST=$host ./scripts/docker-deploy.sh
done
```

### Load Balancing

Use a reverse proxy (nginx/traefik) to distribute load:

```nginx
upstream ai_agents {
    server meatpi:8080;
    server pi2:8080;
    server pi3:8080;
}

server {
    listen 80;
    location / {
        proxy_pass http://ai_agents;
    }
}
```

## 🎯 Best Practices

1. **Resource Monitoring**: Regularly check resource usage
2. **Log Rotation**: Implement log rotation for containers
3. **Health Checks**: Monitor health endpoints
4. **Backup Strategy**: Regular backups of config and models
5. **Security Updates**: Keep Docker and base images updated
6. **Performance Tuning**: Adjust parameters based on usage

## 📞 Support

For Docker-specific issues:
- Check container logs: `docker-compose logs -f`
- Verify resource usage: `docker stats`
- Test health endpoints: `curl http://meatpi-ip:8080/health`
- Review configuration: `docker-compose config`

The Docker deployment provides a robust, scalable solution for running the AI System Administrator Agent on Raspberry Pi 5!
