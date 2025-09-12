# AI System Administrator Agent - User Guide

## 🎯 Overview

Your Raspberry Pi 5 "meatpi" is now running an ultra-efficient AI system administrator agent with remote Qwen3-4B-Thinking model for advanced reasoning capabilities:

- **Qwen3-4B-Thinking (4B parameters)**: Advanced reasoning model for complex system administration, analysis, and problem-solving
- **Ultra-Low Resource Usage**: Only ~384MB memory vs ~6GB with local models
- **API Gateway**: Intelligent interface with security and rate limiting
- **Documentation Site**: Wiki.js documentation on port 3004

## 🌐 Access Points

### Documentation Website
- **URL**: `http://meatpi:3004`
- **Purpose**: Interactive documentation with examples, API usage, and management guides
- **Features**: Search, copy-paste commands, health checks, responsive design

### API Gateway (Recommended)
- **URL**: `http://meatpi:4000`
- **Purpose**: Secure gateway to remote Qwen3-4B-Thinking model
- **Health Check**: `http://meatpi:4000/health`

### Direct Remote LLM Access
- **Qwen3-4B-Thinking**: `http://100.79.227.126:1234`

## 🚀 Quick Start

### Test Your Setup
```bash
# Check if everything is running
curl http://meatpi:4000/health

# Test AI interaction
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, who are you?"}'
```

## 🤖 Remote LLM Capabilities

### Qwen3-4B-Thinking (4B parameters)
**Best for**: Advanced reasoning, complex system administration, analysis, and problem-solving

**Capabilities**:
- ✅ **Advanced Reasoning**: Step-by-step problem solving with detailed explanations
- ✅ **Complex System Analysis**: Deep analysis of system issues and performance
- ✅ **Decision Making**: Strategic recommendations for system configuration
- ✅ **Root Cause Analysis**: Thorough investigation of system problems
- ✅ **Code Generation**: Writing scripts and automation solutions
- ✅ **Security Analysis**: Vulnerability assessment and security recommendations
- ✅ **Performance Optimization**: System tuning and optimization advice
- ✅ **Troubleshooting**: Complex problem diagnosis and resolution

**Examples**:
```bash
# System analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze why my system is running slowly and suggest optimizations"}'

# Troubleshooting
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "I have high CPU usage, help me identify the root cause with detailed analysis"}'

# Decision making
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Should I upgrade my system or optimize current configuration? Provide detailed pros/cons"}'

# Security analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform a security assessment of my system and recommend improvements"}'
```

## 🔧 API Usage Examples

### 1. Standard Usage (Recommended)
The API Gateway provides access to the remote Qwen3-4B-Thinking model:

```bash
# Standard query
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me running processes"}'

# Complex analysis query
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Why is my system experiencing intermittent failures? Provide detailed analysis"}'
```

### 2. Force Model (Qwen3)
```bash
# Explicit Qwen3 model usage
curl -X POST http://meatpi:4000/chat/qwen3 \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze this error log and suggest fixes"}'
```

### 3. Streaming Responses
```bash
# Enable streaming for long responses
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform a comprehensive security audit of my system", "stream": true}'
```

### 4. Direct Remote LLM Access
```bash
# Direct access to remote Qwen3 model
curl -X POST http://100.79.227.126:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen/qwen3-4b-thinking-2507",
    "messages": [{"role": "user", "content": "Show me disk usage"}],
    "max_tokens": 1024
  }'
```

## 📋 Common System Administration Tasks

### System Monitoring
```bash
# Check system status
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Show me current system status, CPU, memory, and disk usage with detailed analysis"}'

# Monitor processes
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze the top 10 processes by CPU usage and identify potential issues"}'

# Check services
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "List all running services and analyze their health and performance"}'
```

### Docker Management
```bash
# Docker status analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze all Docker containers status and provide optimization recommendations"}'

# Docker cleanup with reasoning
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform intelligent cleanup of unused Docker images and containers with detailed reasoning"}'
```

### Network Troubleshooting
```bash
# Network analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform comprehensive network connectivity analysis and identify security issues"}'

# Port analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze what services are running on ports 3000-9000 and assess security risks"}'
```

### Security Analysis
```bash
# Comprehensive security audit
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform a comprehensive security assessment of my system with prioritized recommendations"}'

# User analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze all users and their permissions, identify security risks and suggest improvements"}'
```

## 🛠️ Advanced Usage

### Streaming Responses
```bash
# Stream response for long operations
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze my system performance with detailed recommendations", "stream": true}'
```

### Custom Prompts
```bash
# System-specific prompts
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "As a DevOps engineer, help me optimize my Raspberry Pi 5 server for AI workloads with detailed technical analysis"}'
```

### Batch Operations
```bash
# Complex multi-step analysis
curl -X POST http://meatpi:4000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Perform comprehensive system analysis: check security, performance, and provide optimization recommendations"}'
```

## 🔍 Troubleshooting

### Check Service Status
```bash
# Check all services
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml ps'

# Check specific service logs
ssh inggo@meatpi 'docker logs api-gateway'
ssh inggo@meatpi 'docker logs docs'
```

### Restart Services
```bash
# Restart all services
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml restart'

# Restart specific service
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml restart api-gateway'
```

### Health Checks
```bash
# API Gateway health
curl http://meatpi:4000/health

# Remote LLM availability
curl http://100.79.227.126:1234/v1/models
```

## 📊 Performance Tips

### Optimize Response Time
- **Single Advanced Model**: Qwen3-4B-Thinking handles all complexity levels with advanced reasoning
- **Streaming**: Use streaming for long-form responses to see results as they arrive
- **Be Specific**: Detailed questions yield more comprehensive analysis

### Resource Management
- **Memory Usage**: ~384MB total (ultra-low resource usage)
- **CPU**: Minimal usage with remote processing
- **Response Time**: <3 seconds for simple queries, <8 seconds for complex analysis (includes network latency)

### Best Practices
1. **Be Specific**: Clear, detailed questions get comprehensive analysis with reasoning
2. **Use Streaming**: Enable streaming for complex, long-form responses
3. **Mention Context**: Include your system details (Raspberry Pi 5, Ubuntu, etc.)
4. **Iterate**: Ask follow-up questions for deeper analysis
5. **Leverage Reasoning**: Qwen3 provides step-by-step problem solving

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
