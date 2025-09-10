# AI System Administrator Agent Project Brief

## Project Overview
Create a local AI-powered system administrator agent for Raspberry Pi 5 ("meatpi") that can handle Linux system administration and DevOps tasks through conversational AI interactions.

## Core Requirements

### Target Platform
- **Hardware**: Raspberry Pi 5 (ARM64)
- **OS**: Latest Raspberry Pi OS or DietPi
- **Installation Path**: `/home/inggo/ai-agent`

### AI Framework & Models
- **Orchestration**: AutoGen (latest stable release)
- **Dual Model Backend**: 
  - Gemma 3 (1B parameters) - Port 11434
  - DeepSeek-R1 (1.5B parameters) - Port 11435
- **Runtime**: Ollama optimized for ARM64
- **API Gateway**: Dynamic model routing service
- **Python Environment**: Dedicated virtual environment

### Agent Capabilities
- Accept text instructions for Linux system admin tasks
- Monitor system resources (disk usage, processes, services)
- Perform service management (start/stop/restart)
- Basic troubleshooting and diagnostics
- Conversational response format
- Safe command execution with restrictions

### Interface Requirements
- CLI interface for direct interaction
- Simple local web UI for browser-based access
- REST API endpoints for programmatic access
- API Gateway for dynamic model selection
- Real-time response streaming
- Model switching capabilities

### Security & Safety
- Non-root execution
- Command whitelist/blacklist system
- Firewall and SSH security considerations
- Restricted file system access
- Audit logging for all actions

### Documentation
- Step-by-step installation guide
- Configuration management
- Troubleshooting tips
- Security best practices
- Sample prompts and test cases
- Wiki.js documentation with model comparison
- API Gateway usage instructions
- Model selection guidelines

## Success Criteria
1. Agent successfully installs and runs on Raspberry Pi 5
2. Can perform basic system monitoring tasks
3. Responds conversationally to admin prompts
4. Maintains security restrictions
5. Provides reliable CLI and web interfaces
6. Includes comprehensive documentation

## Project Scope
This is a complete system administration automation project focused on creating a practical, secure, and efficient AI agent for Raspberry Pi system management.
