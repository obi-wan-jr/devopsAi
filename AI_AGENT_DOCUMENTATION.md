# AI System Administrator Agent - User Guide

## 🎯 Overview

Your Raspberry Pi 5 "meatpi" is now running a sophisticated dual-model AI system administrator agent with intelligent routing between two specialized models:

- **Gemma 3 (1B parameters)**: Fast, efficient model for general system administration tasks
- **DeepSeek-R1 (1.5B parameters)**: Advanced reasoning model for complex analysis and problem-solving

## 🌐 Access Points

### Documentation Website
- **URL**: `http://meatpi:3004`
- **Purpose**: Interactive documentation with examples, API usage, and management guides
- **Features**: Search, copy-paste commands, health checks, responsive design

### API Gateway (Recommended)
- **URL**: `http://meatpi:8080`
- **Purpose**: Intelligent routing that automatically selects the best model for your query
- **Health Check**: `http://meatpi:8080/health`

### Direct Model Access
- **Gemma 3**: `http://meatpi:11434`
- **DeepSeek-R1**: `http://meatpi:11435`

## 🚀 Quick Start

### Test Your Setup
```bash
# Check if everything is running
curl http://meatpi:8080/health

# Test AI interaction
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, who are you?"}'
```

## 🤖 Model Selection Guide

### When to Use Gemma 3 (1B)
**Best for**: Quick responses, general tasks, code generation, system monitoring

**Use Gemma 3 when you need**:
- ✅ Quick system status checks
- ✅ Command generation and scripts
- ✅ Simple troubleshooting
- ✅ File operations and directory listings
- ✅ Service management (start/stop/restart)
- ✅ Basic system monitoring

**Examples**:
```bash
# System status
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the current system status and uptime"}'

# Generate a script
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Create a bash script to backup my home directory"}'

# Service management
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How do I restart the nginx service?"}'
```

### When to Use DeepSeek-R1 (1.5B)
**Best for**: Complex reasoning, problem analysis, decision making, root cause analysis

**Use DeepSeek-R1 when you need**:
- ✅ Deep system analysis
- ✅ Complex problem troubleshooting
- ✅ Performance optimization decisions
- ✅ Security vulnerability analysis
- ✅ Root cause investigation
- ✅ Strategic system planning

**Examples**:
```bash
# Complex analysis
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze why my system is running slowly and suggest optimizations"}'

# Troubleshooting
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "I have high CPU usage, help me identify the root cause"}'

# Decision making
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Should I upgrade my system or optimize current configuration?"}'
```

## 🔧 API Usage Examples

### 1. Auto-Selection (Recommended)
The API Gateway automatically chooses the best model:

```bash
# Simple query (will use Gemma 3)
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me running processes"}'

# Complex query (will use DeepSeek-R1)
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Why is my system experiencing intermittent failures?"}'
```

### 2. Force Specific Model
```bash
# Force Gemma 3
curl -X POST http://meatpi:8080/chat/gemma3 \
  -H "Content-Type: application/json" \
  -d '{"message": "List all Docker containers"}'

# Force DeepSeek-R1
curl -X POST http://meatpi:8080/chat/deepseek \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze this error log and suggest fixes"}'
```

### 3. Direct Model Access
```bash
# Direct Gemma 3 access
curl -X POST http://meatpi:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma3:1b",
    "prompt": "Show me disk usage",
    "stream": false
  }'

# Direct DeepSeek-R1 access
curl -X POST http://meatpi:11435/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1:1.5b",
    "prompt": "Analyze system performance",
    "stream": false
  }'
```

## 📋 Common System Administration Tasks

### System Monitoring
```bash
# Check system status
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me current system status, CPU, memory, and disk usage"}'

# Monitor processes
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me the top 10 processes by CPU usage"}'

# Check services
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "List all running services and their status"}'
```

### Docker Management
```bash
# Docker status
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me all Docker containers and their status"}'

# Docker cleanup
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Help me clean up unused Docker images and containers"}'
```

### Network Troubleshooting
```bash
# Network analysis
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Check network connectivity and show open ports"}'

# Port analysis
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me what services are running on ports 3000-9000"}'
```

### Security Analysis
```bash
# Security check
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform a basic security check of my system"}'

# User analysis
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me all users and their permissions"}'
```

## 🛠️ Advanced Usage

### Streaming Responses
```bash
# Stream response for long operations
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze my system performance", "stream": true}'
```

### Custom Prompts
```bash
# System-specific prompts
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "As a DevOps engineer, help me optimize my Raspberry Pi 5 server for AI workloads"}'
```

### Batch Operations
```bash
# Multiple related queries
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Help me set up monitoring for my AI services and create alerts for high resource usage"}'
```

## 🔍 Troubleshooting

### Check Service Status
```bash
# Check all services
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.dual-models.yml ps'

# Check specific service logs
ssh inggo@meatpi 'docker logs api-gateway'
ssh inggo@meatpi 'docker logs ollama-gemma3'
ssh inggo@meatpi 'docker logs ollama-deepseek'
```

### Restart Services
```bash
# Restart all services
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.dual-models.yml restart'

# Restart specific service
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.dual-models.yml restart api-gateway'
```

### Health Checks
```bash
# API Gateway health
curl http://meatpi:8080/health

# Model availability
curl http://meatpi:11434/api/tags
curl http://meatpi:11435/api/tags
```

## 📊 Performance Tips

### Optimize Response Time
- Use **Gemma 3** for simple queries (faster responses)
- Use **DeepSeek-R1** for complex analysis (better quality)
- Let the API Gateway auto-select for best results

### Resource Management
- **Memory Usage**: ~5GB total (Gemma 3: 2GB, DeepSeek-R1: 2.5GB)
- **CPU**: Optimized for Pi 5 ARM64
- **Response Time**: <2 seconds for simple queries, <5 seconds for complex analysis

### Best Practices
1. **Be Specific**: Clear, detailed questions get better answers
2. **Use Context**: Mention your system (Raspberry Pi 5, Ubuntu, etc.)
3. **Iterate**: Ask follow-up questions for clarification
4. **Combine Models**: Use both models for comprehensive analysis

## 🎯 Success Examples

### Quick System Check
```bash
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Give me a quick health check of my Raspberry Pi 5 server"}'
```

### Performance Optimization
```bash
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze my system performance and suggest optimizations for running AI workloads"}'
```

### Incident Response
```bash
curl -X POST http://meatpi:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "My AI services are not responding, help me troubleshoot"}'
```

## 🚀 Getting Started

1. **Test the setup**: `curl http://meatpi:8080/health`
2. **Try a simple query**: Use the examples above
3. **Explore both models**: Test Gemma 3 and DeepSeek-R1
4. **Use auto-selection**: Let the API Gateway choose the best model
5. **Build your workflow**: Integrate into your daily DevOps tasks

Your AI System Administrator Agent is ready to help with all your system administration and DevOps needs! 🎉
