# Technical Context - AI System Administrator Agent

## Technology Stack

### Core AI Framework
- **AutoGen**: Microsoft's multi-agent conversation framework
  - Version: Latest stable (v0.2.x)
  - Purpose: Agent orchestration and workflow management
  - Installation: Python pip package

### LLM Backend Options
1. **llama.cpp** (Primary Choice)
   - Supports GGUF quantized models
   - ARM64 optimized builds available
   - Lower memory footprint
   - Direct Python bindings

2. **Ollama** (Alternative)
   - Easy model management
   - REST API interface
   - Good ARM64 support
   - May have higher resource usage

### Model Selection
- **Qwen2 1.5B**: Lightweight, efficient for Pi 5
  - Format: GGUF quantized (Q4_K_M or Q5_K_M)
  - Size: ~1-2GB
  - Performance: Good for system admin tasks
  - Alternative: TinyLlama 1.1B if Qwen2 unavailable

### Python Environment
- **Python**: 3.9+ (Pi OS default)
- **Virtual Environment**: venv or conda
- **Package Manager**: pip
- **Dependencies**: AutoGen, llama-cpp-python, FastAPI, uvicorn

### System Integration
- **Operating System**: Raspberry Pi OS (64-bit) or DietPi
- **Architecture**: ARM64/aarch64
- **Memory**: 8GB recommended (4GB minimum)
- **Storage**: 32GB+ microSD card
- **Network**: Local network access

### Security Framework
- **User**: Non-root execution (inggo user)
- **Permissions**: sudo access for specific commands only
- **Firewall**: ufw configuration
- **SSH**: Key-based authentication
- **Command Filtering**: Whitelist-based execution

### Interface Technologies
- **CLI**: Python click or argparse
- **Web UI**: FastAPI + HTML/CSS/JavaScript
- **API**: REST endpoints with JSON
- **Real-time**: WebSocket for streaming responses

## Development Environment
- **Local Development**: macOS (current machine)
- **Target Deployment**: Raspberry Pi 5 (meatpi)
- **Deployment Method**: Docker Compose + direct installation
- **Configuration**: Environment variables + YAML config files

## Performance Considerations
- **Memory Usage**: Target <2GB for LLM + AutoGen
- **CPU Usage**: Efficient for background operation
- **Response Time**: <5 seconds for simple queries
- **Concurrent Users**: 1-3 simultaneous sessions
- **Storage**: Minimal disk usage for logs and configs
