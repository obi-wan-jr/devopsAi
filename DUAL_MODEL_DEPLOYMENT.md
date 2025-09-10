# Dual-Model AI System Administrator Agent - Raspberry Pi 5 Deployment

## 🎯 Overview

This deployment provides a sophisticated dual-model AI-powered system administrator agent for your Raspberry Pi 5 server "meatpi" with the following features:

- **Gemma 2 (2B parameters)**: Google's efficient model for general system administration tasks
- **DeepSeek-R1 Distill (1.5B parameters)**: Specialized model for complex reasoning and analysis
- **API Gateway**: Intelligent routing between models based on query type
- **Wiki.js**: Comprehensive documentation and knowledge base
- **Containerized Deployment**: Docker Compose orchestration for reliability

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi 5 with 16GB RAM
- Ubuntu or Raspberry Pi OS (64-bit)
- SSH access configured
- Docker and Docker Compose installed

### 1. Clean Deployment

```bash
# From your local machine - clean deployment
./scripts/nuke-and-pave.sh
./scripts/deploy-dual-models.sh
```

### 2. Verify Deployment

```bash
# Check service status
./scripts/manage-dual-models.sh status

# Test AI interaction
./scripts/manage-dual-models.sh test

# Check health
./scripts/manage-dual-models.sh health
```

## 🌐 Access URLs

Once deployed, access your services at:

- **🧠 Gemma 2 API**: `http://meatpi:11434`
- **🧠 DeepSeek-R1 API**: `http://meatpi:11435`
- **🌐 API Gateway**: `http://meatpi:8080`
- **📚 Wiki.js**: `http://meatpi:3004`
- **📊 Health Check**: `http://meatpi:8080/health`
- **📋 Status**: `http://meatpi:8080/status`

## 🧠 Model Comparison & Usage

### Gemma 2 (2B parameters) - Port 11434
**Best for**: General tasks, Code generation, System monitoring, Troubleshooting

**Use when**:
- You need quick, reliable responses for common system admin tasks
- Generating scripts or commands
- Basic system monitoring and status checks
- Simple troubleshooting

**Direct API**:
```bash
curl -X POST http://meatpi:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma2:2b",
    "prompt": "Show me the current disk usage",
    "stream": false
  }'
```

### DeepSeek-R1 Distill (1.5B parameters) - Port 11435
**Best for**: Complex reasoning, Problem analysis, Decision making, Root cause analysis

**Use when**:
- You need deep analysis or complex problem-solving
- Investigating system issues or failures
- Making decisions about system configuration
- Understanding complex relationships between system components

**Direct API**:
```bash
curl -X POST http://meatpi:11435/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1-distill:1.5b",
    "prompt": "Analyze why my system is running slowly",
    "stream": false
  }'
```

### API Gateway - Port 8080
**Intelligent routing** that automatically selects the best model based on your query

**Auto-selection**:
```bash
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Your question here",
    "stream": false
  }'
```

**Specific model selection**:
```bash
# Use Gemma 2 specifically
curl -X POST http://meatpi:8080/chat/gemma2 \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me running processes"}'

# Use DeepSeek-R1 specifically
curl -X POST http://meatpi:8080/chat/deepseek \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze this error log"}'
```

## 🛠️ Management Commands

### Service Management

```bash
# Check status
./scripts/manage-dual-models.sh status

# View logs
./scripts/manage-dual-models.sh logs
./scripts/manage-dual-models.sh logs api-gateway
./scripts/manage-dual-models.sh logs ollama-gemma2
./scripts/manage-dual-models.sh logs ollama-deepseek

# Start/stop/restart services
./scripts/manage-dual-models.sh start
./scripts/manage-dual-models.sh stop
./scripts/manage-dual-models.sh restart
./scripts/manage-dual-models.sh restart ollama-gemma2

# Update services
./scripts/manage-dual-models.sh update

# Health check
./scripts/manage-dual-models.sh health

# Test AI interaction
./scripts/manage-dual-models.sh test

# Show access URLs
./scripts/manage-dual-models.sh urls

# Show model comparison
./scripts/manage-dual-models.sh models
```

### Cleanup Commands

```bash
# Nuke and pave cleanup
./scripts/nuke-and-pave.sh

# Dry run (see what would be removed)
./scripts/nuke-and-pave.sh --dry-run

# Verify current state
./scripts/nuke-and-pave.sh --verify
```

## 🤖 AI Interaction Examples

### System Monitoring Tasks (Gemma 2)

```bash
# Check system status
curl -X POST http://meatpi:8080/chat/gemma2 \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the current system status"}'

# Monitor disk usage
curl -X POST http://meatpi:8080/chat/gemma2 \
  -H "Content-Type: application/json" \
  -d '{"message": "Check disk usage and show top directories"}'

# List running processes
curl -X POST http://meatpi:8080/chat/gemma2 \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me all running processes"}'
```

### Complex Analysis Tasks (DeepSeek-R1)

```bash
# Analyze system performance
curl -X POST http://meatpi:8080/chat/deepseek \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze why my system is running slowly and suggest optimizations"}'

# Troubleshoot issues
curl -X POST http://meatpi:8080/chat/deepseek \
  -H "Content-Type: application/json" \
  -d '{"message": "I have high CPU usage, help me identify the root cause"}'

# Decision making
curl -X POST http://meatpi:8080/chat/deepseek \
  -H "Content-Type: application/json" \
  -d '{"message": "Should I upgrade my system or optimize current configuration?"}'
```

### Auto-Selection Examples

```bash
# Simple query (will use Gemma 2)
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the current uptime"}'

# Complex query (will use DeepSeek-R1)
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Why is my system experiencing intermittent failures?"}'
```

## 📚 Wiki.js Setup

1. Access `http://meatpi:3004`
2. Complete the initial setup wizard
3. Create an admin account
4. Configure your site settings
5. Add documentation for:
   - Model comparison and usage guidelines
   - API examples and best practices
   - Troubleshooting guides
   - System administration workflows

## 🔧 Configuration

### Environment Variables

The deployment uses these key environment variables:

```yaml
# API Gateway Configuration
GATEWAY_HOST: 0.0.0.0
GATEWAY_PORT: 8080
ADMIN_PORT: 8081

# Model URLs
GEMMA2_URL: http://ollama-gemma2:11434
DEEPSEEK_URL: http://ollama-deepseek:11434

# Model IDs
GEMMA2_MODEL: gemma2:2b
DEEPSEEK_MODEL: deepseek-r1-distill:1.5b

# Logging
LOG_LEVEL: INFO
```

### Docker Compose Services

- **ollama-gemma2**: Gemma 2 model serving (port 11434)
- **ollama-deepseek**: DeepSeek-R1 Distill model serving (port 11435)
- **api-gateway**: Intelligent model routing (ports 8080, 8081)
- **wiki**: Wiki.js documentation (port 3004)

## 🔒 Security Features

- **Non-root Execution**: All containers run as non-root user
- **Command Whitelisting**: Only approved commands can execute
- **Audit Logging**: Complete activity tracking
- **Resource Limits**: CPU and memory constraints
- **Network Isolation**: Services communicate through internal network

## 📊 Performance Characteristics

### Resource Usage

- **Memory**: ~6GB total
  - Gemma 2: 3GB
  - DeepSeek-R1: 2.5GB
  - API Gateway: 512MB
  - Wiki: 512MB
- **CPU**: Optimized for Pi 5 ARM64
- **Storage**: ~8GB for models and data
- **Network**: Local-only communication

### Response Times

- **Simple Queries**: <2 seconds
- **Complex Analysis**: <5 seconds
- **Model Loading**: ~15-20 seconds per model
- **Service Startup**: ~45-60 seconds

## 🚨 Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   ./scripts/manage-dual-models.sh logs
   ./scripts/manage-dual-models.sh status
   ```

2. **Models not loading**
   ```bash
   ./scripts/manage-dual-models.sh restart ollama-gemma2
   ./scripts/manage-dual-models.sh restart ollama-deepseek
   ./scripts/manage-dual-models.sh logs ollama-gemma2
   ```

3. **API Gateway issues**
   ```bash
   ./scripts/manage-dual-models.sh restart api-gateway
   ./scripts/manage-dual-models.sh logs api-gateway
   ```

4. **Port conflicts**
   ```bash
   # Check what's using ports
   ssh inggo@meatpi "sudo netstat -tlnp | grep -E ':(11434|11435|8080|3004)'"
   ```

5. **Memory issues**
   ```bash
   # Check memory usage
   ssh inggo@meatpi "free -h && docker stats --no-stream"
   ```

### Log Locations

- **Service Logs**: `docker-compose logs -f`
- **Application Logs**: `/home/inggo/ai-agent/logs/`
- **Model Logs**: Docker container logs
- **Wiki Logs**: `/home/inggo/ai-agent/logs/wiki/`

### Recovery Procedures

1. **Complete Reset**
   ```bash
   ./scripts/nuke-and-pave.sh
   ./scripts/deploy-dual-models.sh
   ```

2. **Service Restart**
   ```bash
   ./scripts/manage-dual-models.sh restart
   ```

3. **Model Re-download**
   ```bash
   ./scripts/manage-dual-models.sh stop
   ssh inggo@meatpi "docker volume rm gemma2_data deepseek_data"
   ./scripts/deploy-dual-models.sh --no-models
   ```

## 🔄 Maintenance

### Regular Tasks

1. **Update Services**
   ```bash
   ./scripts/manage-dual-models.sh update
   ```

2. **Health Monitoring**
   ```bash
   ./scripts/manage-dual-models.sh health
   ```

3. **Log Rotation**
   ```bash
   ssh inggo@meatpi "sudo logrotate -f /etc/logrotate.conf"
   ```

4. **System Updates**
   ```bash
   ssh inggo@meatpi "sudo apt update && sudo apt upgrade -y"
   ```

### Backup Procedures

1. **Configuration Backup**
   ```bash
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/config/ ./backup/config/
   ```

2. **Wiki Data Backup**
   ```bash
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/data/wiki/ ./backup/wiki/
   ```

3. **Model Data Backup**
   ```bash
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/data/gemma2/ ./backup/gemma2/
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/data/deepseek/ ./backup/deepseek/
   ```

## 📈 Monitoring

### Health Checks

- **Gemma 2**: `http://meatpi:11434/api/tags`
- **DeepSeek-R1**: `http://meatpi:11435/api/tags`
- **API Gateway**: `http://meatpi:8080/health`
- **Wiki**: `http://meatpi:3004`

### Resource Monitoring

```bash
# Check container resource usage
./scripts/manage-dual-models.sh status

# Check system resources
ssh inggo@meatpi "htop"

# Check disk usage
ssh inggo@meatpi "df -h"
```

## 🎯 Success Criteria

✅ **Gemma 2 (2B parameters)**: Successfully deployed and responding  
✅ **DeepSeek-R1 Distill (1.5B parameters)**: Successfully deployed and responding  
✅ **API Gateway**: Intelligent model routing working  
✅ **Wiki.js**: Documentation service on port 3004  
✅ **Dual Model Architecture**: Both models running simultaneously  
✅ **Dynamic Model Selection**: Auto-selection based on query type  
✅ **Containerized Deployment**: Docker Compose orchestration  
✅ **Security**: Non-root execution and command validation  
✅ **Documentation**: Comprehensive setup and usage guides  

## 🎉 Conclusion

Your Dual-Model AI System Administrator Agent is now ready for production use on Raspberry Pi 5 "meatpi"! The system provides:

- **Intelligent Model Selection**: Automatically chooses the best model for each task
- **Specialized Capabilities**: Gemma 2 for general tasks, DeepSeek-R1 for complex analysis
- **Comprehensive Documentation**: Wiki.js with detailed usage guidelines
- **Easy Management**: Simple scripts for all operations
- **Production-Ready**: Robust deployment with health monitoring

Start using your dual-model AI agent by accessing `http://meatpi:8080` or using the direct model APIs!
