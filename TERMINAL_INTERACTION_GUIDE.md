# 🤖 AI System Administrator Agent - Terminal Interaction Guide

## 🚀 Quick Start

### 1. Connect to Your Raspberry Pi
```bash
ssh inggo@meatpi
```

### 2. Navigate to Project Directory
```bash
cd /home/inggo/ai-agent
```

### 3. Start Interactive Chat
```bash
python3 src/cli_chat.py
```

## 💬 Interactive Chat Commands

Once in the interactive chat, you can use these commands:

| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/models` | List available AI models |
| `/model gemma3` | Switch to Gemma 3 model |
| `/model deepseek` | Switch to DeepSeek-R1 model |
| `/auto` | Use automatic model selection |
| `/quit` | Exit the chat |

## 🎯 Single Command Usage

### Quick Questions
```bash
# Ask a simple question
python3 src/cli_chat.py "Show me system status"

# Use specific model
python3 src/cli_chat.py --model deepseek "Analyze this error log"

# Use Gemma 3 for quick tasks
python3 src/cli_chat.py --model gemma3 "Generate a backup script"
```

### Examples
```bash
# System administration tasks
python3 src/cli_chat.py "How do I check disk usage?"
python3 src/cli_chat.py "Show me running Docker containers"
python3 src/cli_chat.py "What's my current memory usage?"

# Troubleshooting
python3 src/cli_chat.py --model deepseek "My server is running slow, help me diagnose"
python3 src/cli_chat.py "Docker container won't start, what should I check?"

# Script generation
python3 src/cli_chat.py "Create a script to monitor disk space"
python3 src/cli_chat.py "Generate a backup script for my database"
```

## 🔧 Alternative Access Methods

### Direct API Gateway Access
```bash
# Chat via API Gateway
curl -X POST http://localhost:9000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, show me system status"}'

# Use specific model
curl -X POST http://localhost:9000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Analyze this", "model": "deepseek"}'
```

### Direct Model Access

#### Gemma 3 (Port 11434)
```bash
curl http://localhost:11434/api/generate \
  -d '{"model": "gemma3:1b", "prompt": "Hello, how are you?"}'
```

#### DeepSeek-R1 (Port 11435)
```bash
curl http://localhost:11435/api/generate \
  -d '{"model": "deepseek-r1:1.5b", "prompt": "Hello, how are you?"}'
```

## 🧠 Model Selection Guide

### When to Use Gemma 3 (1B)
- **Fast responses** for simple tasks
- **System monitoring** commands
- **Script generation** and automation
- **Quick troubleshooting** steps
- **General system administration**

### When to Use DeepSeek-R1 (1.5B)
- **Complex reasoning** and analysis
- **Problem diagnosis** and root cause analysis
- **Decision making** for system changes
- **Detailed troubleshooting** workflows
- **Architecture planning** and optimization

### Auto-Selection
The system automatically chooses the best model based on your message content:
- Messages with "analyze", "why", "problem", "debug" → DeepSeek-R1
- Messages with "show", "list", "create", "script" → Gemma 3

## 📋 Common Use Cases

### System Monitoring
```bash
python3 src/cli_chat.py "Show me current system resources"
python3 src/cli_chat.py "What processes are using the most CPU?"
python3 src/cli_chat.py "Check disk space usage"
```

### Docker Management
```bash
python3 src/cli_chat.py "List all running Docker containers"
python3 src/cli_chat.py "How do I restart a Docker container?"
python3 src/cli_chat.py "Show me Docker container logs"
```

### Network Troubleshooting
```bash
python3 src/cli_chat.py "Check network connectivity"
python3 src/cli_chat.py "Show me open ports"
python3 src/cli_chat.py "Test DNS resolution"
```

### Security Analysis
```bash
python3 src/cli_chat.py --model deepseek "Analyze system security"
python3 src/cli_chat.py "Check for failed login attempts"
python3 src/cli_chat.py "Show me firewall status"
```

### Performance Optimization
```bash
python3 src/cli_chat.py --model deepseek "My system is slow, help me optimize"
python3 src/cli_chat.py "Analyze memory usage patterns"
python3 src/cli_chat.py "Check for performance bottlenecks"
```

## 🛠️ Troubleshooting

### If CLI Chat Doesn't Start
```bash
# Check if Python 3 is available
python3 --version

# Install required dependencies
pip3 install httpx

# Check if API Gateway is running
curl http://localhost:9000/health
```

### If Models Don't Respond
```bash
# Check if Ollama services are running
docker ps | grep ollama

# Check model availability
curl http://localhost:11434/api/tags
curl http://localhost:11435/api/tags
```

### If API Gateway is Down
```bash
# Restart the API Gateway
cd /home/inggo/ai-agent
docker-compose -f docker-compose.dual-models.yml restart api-gateway
```

## 📚 Additional Resources

- **Documentation Website**: `http://meatpi:3004` (via Tailscale)
- **API Gateway Health**: `http://localhost:9000/health`
- **Model Information**: `http://localhost:9000/models`

## 🎉 You're Ready!

Your AI System Administrator Agent is now ready for terminal interaction. The CLI interface provides the most reliable way to interact with your AI engineer, with full access to both Gemma 3 and DeepSeek-R1 models.

Start with: `python3 src/cli_chat.py` and begin chatting with your AI assistant!
