# Remote LLM AI System Administrator Agent - Raspberry Pi 5 Deployment

## 🎯 Overview

This deployment provides a sophisticated AI-powered system administrator agent for your Raspberry Pi 5 server "meatpi" with the following features:

- **Remote Qwen3-4B-Thinking**: Advanced reasoning model hosted remotely for complex system administration tasks
- **API Gateway**: Intelligent interface to the remote LLM service
- **Wiki.js**: Comprehensive documentation and knowledge base
- **Containerized Deployment**: Docker Compose orchestration for reliability
- **Ultra-Low Resource Usage**: Only ~384MB memory vs ~6GB with local models

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
./scripts/deploy-remote-llm.sh
```

### 2. Verify Deployment

```bash
# Check service status
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml ps"

# Test AI interaction
curl -X POST http://meatpi:4000/chat -H "Content-Type: application/json" -d '{"message": "Hello, can you help me with system administration?"}'

# Check health
curl http://meatpi:4000/health
```

## 🌐 Access URLs

Once deployed, access your services at:

- **🌐 API Gateway**: `http://meatpi:4000`
- **📚 Wiki.js**: `http://meatpi:3004`
- **📊 Health Check**: `http://meatpi:4000/health`
- **📋 Status**: `http://meatpi:4000/status`
- **🧠 Remote LLM**: `http://100.79.227.126:1234` (direct access)

## 🧠 Remote LLM Usage

### Qwen3-4B-Thinking (4B parameters) - Remote Service
**Best for**: Advanced reasoning, Complex problem solving, System analysis, Decision making, Root cause analysis, Code generation

**Capabilities**:
- Advanced reasoning with step-by-step thinking
- Complex system administration tasks
- Deep analysis of system issues
- Code generation and script writing
- Troubleshooting and diagnostics
- Decision making for system configuration

**Direct API**:
```bash
curl -X POST http://100.79.227.126:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen/qwen3-4b-thinking-2507",
    "messages": [{"role": "user", "content": "Show me the current disk usage"}],
    "max_tokens": 1024
  }'
```

### API Gateway - Port 8080
**Simplified interface** to the remote LLM service

**Standard usage**:
```bash
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Your question here",
    "stream": false
  }'
```

**Streaming responses**:
```bash
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Analyze my system performance",
    "stream": true
  }'
```

## 🛠️ Management Commands

### Service Management

```bash
# Check status
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml ps"

# View logs
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml logs -f"
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml logs -f api-gateway"

# Start/stop/restart services
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml up -d"
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml down"
ssh inggo@meatpi "cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml restart"

# Health check
curl http://meatpi:4000/health

# Test AI interaction
curl -X POST http://meatpi:4000/chat -H "Content-Type: application/json" -d '{"message": "Hello"}'

# Show access URLs
echo "API Gateway: http://meatpi:4000"
echo "Wiki.js: http://meatpi:3004"
echo "Remote LLM: http://100.79.227.126:1234"
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

### System Monitoring Tasks (Gemma 3)

```bash
# Check system status
curl -X POST http://meatpi:8080/chat/gemma3 \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the current system status"}'

# Monitor disk usage
curl -X POST http://meatpi:8080/chat/gemma3 \
  -H "Content-Type: application/json" \
  -d '{"message": "Check disk usage and show top directories"}'

# List running processes
curl -X POST http://meatpi:8080/chat/gemma3 \
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
# Simple query (will use Gemma 3)
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
GEMMA2_URL: http://ollama-gemma3:11434
DEEPSEEK_URL: http://ollama-deepseek:11434

# Model IDs
GEMMA2_MODEL: gemma3:1b
DEEPSEEK_MODEL: deepseek-r1:1.5b

# Logging
LOG_LEVEL: INFO
```

### Docker Compose Services

- **ollama-gemma3**: Gemma 3 model serving (port 11434)
- **ollama-deepseek**: DeepSeek-R1 model serving (port 11435)
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

- **Memory**: ~384MB total
  - API Gateway: 256MB
  - Wiki: 128MB
- **CPU**: Minimal usage (only API Gateway and Wiki)
- **Storage**: ~1GB for application and data
- **Network**: Communicates with remote LLM service

### Response Times

- **Simple Queries**: <3 seconds (includes network latency)
- **Complex Analysis**: <8 seconds (includes network latency)
- **Model Loading**: Instant (remote service)
- **Service Startup**: ~30 seconds

## 🚨 Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   ./scripts/manage-dual-models.sh logs
   ./scripts/manage-dual-models.sh status
   ```

2. **Models not loading**
   ```bash
   ./scripts/manage-dual-models.sh restart ollama-gemma3
   ./scripts/manage-dual-models.sh restart ollama-deepseek
   ./scripts/manage-dual-models.sh logs ollama-gemma3
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
   ssh inggo@meatpi "docker volume rm gemma3_data deepseek_data"
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
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/data/gemma3/ ./backup/gemma3/
   rsync -avz inggo@meatpi:/home/inggo/ai-agent/data/deepseek/ ./backup/deepseek/
   ```

## 📈 Monitoring

### Health Checks

- **Gemma 3**: `http://meatpi:11434/api/tags`
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

✅ **Remote Qwen3-4B-Thinking**: Successfully connected and responding  
✅ **API Gateway**: Remote LLM integration working  
✅ **Wiki.js**: Documentation service on port 3004  
✅ **Ultra-Low Resource Usage**: Only ~384MB memory consumption  
✅ **Fast Startup**: ~30 second service initialization  
✅ **Containerized Deployment**: Docker Compose orchestration  
✅ **Security**: Non-root execution and command validation  
✅ **Documentation**: Comprehensive setup and usage guides  
✅ **Network Integration**: Seamless remote LLM communication  

## 🎉 Conclusion

Your Remote LLM AI System Administrator Agent is now ready for production use on Raspberry Pi 5 "meatpi"! The system provides:

- **Advanced Reasoning**: Qwen3-4B-Thinking with step-by-step problem solving
- **Ultra-Low Resource Usage**: Only ~384MB memory vs ~6GB with local models
- **Fast Startup**: ~30 second initialization vs ~60 seconds with local models
- **Comprehensive Documentation**: Wiki.js with detailed usage guidelines
- **Easy Management**: Simple Docker Compose commands for all operations
- **Production-Ready**: Robust deployment with health monitoring
- **Network Efficiency**: Leverages remote LLM service for processing

Start using your remote LLM AI agent by accessing `http://meatpi:8080` or using the direct remote LLM API at `http://100.79.227.126:1234`!
