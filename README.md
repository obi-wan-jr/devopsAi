# AI System Administrator Agent

An AI-powered system administrator agent designed specifically for Raspberry Pi 5, using a remote Qwen3-4B-Thinking service for advanced reasoning. This agent can handle Linux system administration and DevOps tasks through conversational AI interactions with ultra-low resource usage (~384MB memory).

## 🚀 Features

- **AI-Powered System Administration**: Conversational interface for Linux system tasks
- **Raspberry Pi 5 Optimized**: Designed specifically for ARM64 architecture with minimal resource usage
- **Remote Qwen3-4B-Thinking**: Advanced reasoning model hosted remotely for complex analysis
- **API Gateway**: Intelligent routing with security and rate limiting
- **Documentation Site**: Wiki.js documentation and API reference on port 3004
- **Ultra-Low Resource Usage**: ~384MB memory vs ~6GB with local models
- **Secure Command Execution**: Whitelist-based security with audit logging (legacy mode)
- **Multiple Interfaces**: CLI, Web UI, and REST API

## 📋 Requirements

### Hardware
- **Raspberry Pi 5** (ARM64/aarch64)
- **8GB RAM** (minimum 4GB, 8GB recommended)
- **32GB+ microSD card** (Class 10 or better)
- **Network connection** (Ethernet or WiFi)

### Software
- **Raspberry Pi OS** (64-bit) or **DietPi**
- **Python 3.9+** (3.11 recommended)
- **Git** and build tools
- **Docker** (optional, for containerized deployment)

## 🛠️ Installation

### Quick Installation (Remote LLM)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/ai-sysadmin-agent.git
   cd ai-sysadmin-agent
   ```

2. **Deploy to Raspberry Pi**:
   ```bash
   # From local machine
   chmod +x scripts/deploy-remote-llm.sh
   ./scripts/deploy-remote-llm.sh
   ```

3. **Access the services**:
   - **API Gateway**: `http://your-pi-ip:4000`
   - **Documentation**: `http://your-pi-ip:3004`
   - **Health Check**: `http://your-pi-ip:4000/health`

### Legacy Installation (Local Models)

If you prefer the legacy mode with local models:

1. **Update system packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y build-essential cmake git python3 python3-pip python3-venv
   ```

2. **Set up Python environment**:
   ```bash
   python3 -m venv ai-agent-env
   source ai-agent-env/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. **Download models and build**:
   ```bash
   chmod +x scripts/setup_model.sh
   ./scripts/setup_model.sh
   git clone https://github.com/ggerganov/llama.cpp.git
   cd llama.cpp && make -j$(nproc)
   ```

## 🎯 Usage

### Remote LLM Mode (Recommended)

The easiest way to interact with the agent is through the API Gateway:

1. **Access the API Gateway**:
   ```
   http://your-pi-ip:4000
   ```

2. **Check documentation**:
   ```
   http://your-pi-ip:3004
   ```

3. **API usage**:
   ```bash
   # Send a chat request
   curl -X POST http://your-pi-ip:4000/chat \
     -H "Content-Type: application/json" \
     -d '{"message": "Check disk usage"}'

   # Check health
   curl http://your-pi-ip:4000/health
   ```

### CLI Interface

For command-line usage with the remote LLM:

```bash
# Install CLI dependencies
pip install httpx rich

# Run interactive chat
python -m src.cli_chat

# Or specify API URL
python -m src.cli_chat --url http://your-pi-ip:4000
```

### Legacy Mode (Local Models)

For the legacy mode with local models, see the deployment documentation.

## 💬 Example Prompts

Here are some example prompts you can try with the agent:

### System Monitoring
- "Check the current disk usage"
- "Show me the system memory usage"
- "What's the system uptime?"
- "List all running processes"
- "Show me the system load average"

### Service Management
- "Restart the nginx service"
- "Check the status of all services"
- "Start the docker service"
- "Stop the apache service"
- "Show me failed services"

### Process Management
- "Show me processes using the most CPU"
- "Kill the process with PID 1234"
- "Find processes listening on port 80"
- "Show me zombie processes"

### Network Diagnostics
- "Check network connectivity to google.com"
- "Show me open network ports"
- "Display network interface statistics"
- "Test DNS resolution"

### Log Analysis
- "Show me recent system logs"
- "Check for error messages in the logs"
- "Display authentication failures"
- "Show me failed login attempts"

## 🔧 Configuration

### Remote LLM Configuration

The API Gateway is configured via environment variables in `docker-compose.remote-llm.yml`:

```yaml
environment:
  - REMOTE_LLM_URL=http://100.79.227.126:1234
  - REMOTE_LLM_MODEL=qwen/qwen3-4b-thinking-2507
  - API_KEY=your-optional-api-key  # Optional authentication
  - RATE_LIMIT_PER_MINUTE=60       # Rate limiting
  - ALLOWED_ORIGINS=http://localhost:3004,http://localhost:8080
```

### Ports

- **API Gateway**: `4000` (maps to container port `8080`)
- **Documentation Site**: `3004`
- **Health Check**: `4000/health`

### Legacy Configuration (Local Models)

For legacy mode with local models, see the configuration files in `config/` directory and the deprecated `docker-compose.dual-models.yml`.

## 🚀 Deployment Modes

This project supports two deployment modes:

### 1. Remote LLM Mode (Recommended)
- **Pros**: Ultra-low resource usage (~384MB), advanced reasoning, fast deployment
- **Cons**: Requires network connectivity to remote LLM service
- **Use case**: Production deployment on resource-constrained systems
- **Files**: `docker-compose.remote-llm.yml`, `scripts/deploy-remote-llm.sh`

### 2. Local Models Mode (Legacy)
- **Pros**: No network dependency, full local control
- **Cons**: High resource usage (~6GB memory), slower deployment, complex setup
- **Use case**: Offline environments, development/testing
- **Files**: `docker-compose.dual-models.yml` (deprecated), `scripts/deploy-dual-models.sh` (deprecated)

## 🔒 Security Features

### API Gateway Security
- **Optional API Key Authentication**: Configurable via `API_KEY` environment variable
- **Rate Limiting**: Configurable per-IP rate limiting (default: 60 requests/minute)
- **CORS Protection**: Restrict origins to allowed domains
- **Request Validation**: Input sanitization and validation

### Legacy Command Validation (Local Mode)
- **Whitelist-based**: Only pre-approved commands can be executed
- **Pattern matching**: Blocks dangerous command patterns
- **Path restrictions**: Prevents access to sensitive directories
- **Resource limits**: CPU, memory, and execution time limits

### Audit Logging
- **Complete audit trail**: All requests, responses, and commands logged
- **Security events**: Failed attempts and blocked commands tracked
- **Log rotation**: Automatic cleanup of old logs
- **Structured logging**: JSON format for easy analysis

### System Security
- **Non-root execution**: Agent runs as regular user
- **Firewall configuration**: Only necessary ports open
- **SSH security**: Key-based authentication recommended
- **Process isolation**: Limited system access

## 🐳 Docker Deployment

### Remote LLM Deployment (Recommended)

For the remote LLM deployment:

1. **Deploy to Raspberry Pi**:
   ```bash
   ./scripts/deploy-remote-llm.sh
   ```

2. **Check status**:
   ```bash
   ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml ps'
   ```

3. **View logs**:
   ```bash
   ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.remote-llm.yml logs -f'
   ```

### Legacy Docker Deployment

For local model deployment:

```bash
docker-compose -f docker-compose.dual-models.yml up -d
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
chmod +x scripts/test_agent.sh
./scripts/test_agent.sh
```

The test suite includes:
- Python environment validation
- Model loading tests
- Agent import tests
- Web interface tests
- System command execution tests
- Security feature tests

## 📊 Monitoring

### System Service

The agent runs as a systemd service:

```bash
# Check status
sudo systemctl status ai-sysadmin-agent

# View logs
sudo journalctl -u ai-sysadmin-agent -f

# Restart service
sudo systemctl restart ai-sysadmin-agent

# Stop service
sudo systemctl stop ai-sysadmin-agent
```

### Health Checks

- **Web interface**: `http://your-pi-ip:8080/health`
- **API endpoint**: `http://your-pi-ip:8081/api/status`
- **WebSocket**: `ws://your-pi-ip:8080/ws`

## 🔧 Troubleshooting

### Common Issues

#### 1. Model Loading Errors
```bash
# Check if model file exists
ls -la /home/inggo/ai-agent/models/

# Test model loading
cd /home/inggo/ai-agent
source ai-agent-env/bin/activate
python3 -c "from llama_cpp import Llama; Llama('models/qwen2-1.5b-q4_k_m.gguf')"
```

#### 2. Permission Issues
```bash
# Fix ownership
sudo chown -R inggo:inggo /home/inggo/ai-agent

# Fix permissions
chmod +x /home/inggo/ai-agent/start.sh
chmod +x /home/inggo/ai-agent/scripts/*.sh
```

#### 3. Port Conflicts
```bash
# Check what's using the ports
sudo netstat -tlnp | grep :8080
sudo netstat -tlnp | grep :8081

# Kill conflicting processes
sudo kill -9 <PID>
```

#### 4. Memory Issues
```bash
# Check memory usage
free -h

# Check swap
swapon --show

# Add swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 5. Python Environment Issues
```bash
# Recreate virtual environment
cd /home/inggo/ai-agent
rm -rf ai-agent-env
python3 -m venv ai-agent-env
source ai-agent-env/bin/activate
pip install -r requirements.txt
```

### Performance Optimization

#### 1. Model Optimization
- Use Q2_K quantization for lower memory usage
- Reduce context length for faster inference
- Adjust thread count based on CPU cores

#### 2. System Optimization
- Enable GPU acceleration if available
- Use SSD storage for better I/O performance
- Increase swap space for memory-intensive operations

#### 3. Network Optimization
- Use local network for faster model downloads
- Configure proxy if behind corporate firewall
- Enable compression for API responses

## 📚 API Reference

### REST API Endpoints

#### POST `/chat`
Send a message to the remote LLM via the API Gateway.

**Request**:
```json
{
  "message": "Check disk usage",
  "model": "qwen3",
  "stream": false
}
```

**Response**:
```json
{
  "response": "I'll help you check the disk usage...",
  "model_used": "qwen3",
  "timestamp": "2024-01-01T12:00:00",
  "processing_time": 2.5,
  "tokens_used": null
}
```

#### POST `/chat/{model_id}`
Send a message to a specific model (qwen3).

**Request**: Same as `/chat`

#### GET `/status`
Get gateway and model status information.

**Response**:
```json
{
  "status": "healthy",
  "models": {
    "qwen3": {
      "name": "Qwen3-4B-Thinking",
      "status": "healthy",
      "url": "http://100.79.227.126:1234",
      "model_id": "qwen/qwen3-4b-thinking-2507",
      "last_health_check": "2024-01-01T12:00:00"
    }
  },
  "uptime": 3600.5,
  "total_requests": 42,
  "requests_by_model": {"qwen3": 42}
}
```

#### GET `/models`
List available models and their capabilities.

**Response**:
```json
{
  "models": {
    "qwen3": {
      "name": "Qwen3-4B-Thinking",
      "description": "Advanced reasoning model for complex system administration tasks",
      "strengths": ["Advanced reasoning", "Complex problem solving", "System analysis"],
      "status": "available"
    }
  }
}
```

#### GET `/health`
Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00"
}
```

### Authentication

If `API_KEY` is configured, include the header:
```
X-API-Key: your-api-key-here
```

### Rate Limiting

- Default: 60 requests per minute per IP
- Configurable via `RATE_LIMIT_PER_MINUTE` environment variable

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes
4. Run tests: `./scripts/test_agent.sh`
5. Commit your changes: `git commit -am 'Add feature'`
6. Push to the branch: `git push origin feature-name`
7. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Microsoft AutoGen** for the multi-agent conversation framework
- **Qwen Team** for the Qwen2 language model
- **llama.cpp** for efficient model inference
- **FastAPI** for the web framework
- **Raspberry Pi Foundation** for the amazing hardware platform

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/ai-sysadmin-agent/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/ai-sysadmin-agent/discussions)
- **Documentation**: [Wiki](https://github.com/your-username/ai-sysadmin-agent/wiki)

## 🔄 Updates

To update the agent:

```bash
cd /home/inggo/ai-agent
git pull origin main
source ai-agent-env/bin/activate
pip install -r requirements.txt --upgrade
sudo systemctl restart ai-sysadmin-agent
```

---

**Happy System Administration with AI! 🤖✨**
