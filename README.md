# AI System Administrator Agent

An AI-powered system administrator agent designed specifically for Raspberry Pi 5, using AutoGen for orchestration and Qwen2 1.5B as the reasoning engine. This agent can handle Linux system administration and DevOps tasks through conversational AI interactions.

## 🚀 Features

- **AI-Powered System Administration**: Conversational interface for Linux system tasks
- **Raspberry Pi 5 Optimized**: Designed specifically for ARM64 architecture
- **Secure Command Execution**: Whitelist-based security with audit logging
- **Multiple Interfaces**: CLI, Web UI, and REST API
- **Real-time Monitoring**: System resource monitoring and service management
- **AutoGen Integration**: Advanced multi-agent conversation framework
- **Qwen2 1.5B Backend**: Efficient, quantized language model

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

### Quick Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/ai-sysadmin-agent.git
   cd ai-sysadmin-agent
   ```

2. **Run the installation script**:
   ```bash
   chmod +x scripts/install.sh
   ./scripts/install.sh
   ```

3. **Start the agent**:
   ```bash
   cd /home/inggo/ai-agent
   ./start.sh
   ```

### Manual Installation

If you prefer manual installation or need to customize the setup:

1. **Update system packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y build-essential cmake git python3 python3-pip python3-venv
   ```

2. **Create project directory**:
   ```bash
   mkdir -p /home/inggo/ai-agent
   cd /home/inggo/ai-agent
   ```

3. **Set up Python environment**:
   ```bash
   python3 -m venv ai-agent-env
   source ai-agent-env/bin/activate
   pip install --upgrade pip
   ```

4. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

5. **Download the model**:
   ```bash
   chmod +x scripts/setup_model.sh
   ./scripts/setup_model.sh
   ```

6. **Build llama.cpp**:
   ```bash
   git clone https://github.com/ggerganov/llama.cpp.git
   cd llama.cpp
   make -j$(nproc)
   ```

## 🎯 Usage

### Web Interface

The easiest way to interact with the agent is through the web interface:

1. **Start the agent**:
   ```bash
   cd /home/inggo/ai-agent
   ./start.sh
   ```

2. **Open your browser** and navigate to:
   ```
   http://your-pi-ip:8080
   ```

3. **Start chatting** with the agent about system administration tasks!

### CLI Interface

For command-line usage:

```bash
cd /home/inggo/ai-agent
source ai-agent-env/bin/activate
python -m src.interfaces.cli
```

### API Interface

The agent also provides a REST API:

```bash
# Send a request
curl -X POST http://localhost:8081/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Check disk usage"}'

# Get agent status
curl http://localhost:8081/api/status
```

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

### Agent Configuration (`config/agent.yaml`)

```yaml
agent:
  name: "SysAdminAgent"
  model:
    path: "/home/inggo/ai-agent/models/qwen2-1.5b-q4_k_m.gguf"
    backend: "llama.cpp"
    context_length: 2048
    temperature: 0.7
```

### Security Configuration (`config/security.yaml`)

```yaml
security:
  commands:
    allowed:
      - "df"
      - "du"
      - "systemctl"
      - "ps"
      # ... more allowed commands
    forbidden:
      - "rm -rf /"
      - "sudo su"
      - "passwd"
      # ... more forbidden commands
```

### Interface Configuration (`config/interfaces.yaml`)

```yaml
interfaces:
  web:
    enabled: true
    host: "0.0.0.0"
    port: 8080
  cli:
    enabled: true
  api:
    enabled: true
    port: 8081
```

## 🔒 Security Features

### Command Validation
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

For containerized deployment:

1. **Build the containers**:
   ```bash
   docker-compose build
   ```

2. **Start the services**:
   ```bash
   docker-compose up -d
   ```

3. **Check status**:
   ```bash
   docker-compose ps
   docker-compose logs -f
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

#### POST `/api/chat`
Send a message to the agent.

**Request**:
```json
{
  "message": "Check disk usage"
}
```

**Response**:
```json
{
  "response": "I'll check the disk usage for you...",
  "status": "success"
}
```

#### GET `/api/status`
Get agent status information.

**Response**:
```json
{
  "name": "SysAdminAgent",
  "version": "1.0.0",
  "model_loaded": true,
  "autogen_initialized": true,
  "conversation_length": 5,
  "security_enabled": true,
  "audit_logging": true
}
```

#### GET `/health`
Health check endpoint.

**Response**:
```json
{
  "status": "healthy",
  "agent": { ... }
}
```

### WebSocket API

Connect to `ws://your-pi-ip:8080/ws` for real-time communication.

**Message Format**:
```json
{
  "type": "chat",
  "message": "Your message here"
}
```

**Response Format**:
```json
{
  "type": "response",
  "message": "Agent response here"
}
```

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
