# Troubleshooting Guide

This guide helps you resolve common issues with the AI System Administrator Agent.

## 🔍 Quick Diagnostics

### Check System Status
```bash
# Check if the service is running
sudo systemctl status ai-sysadmin-agent

# Check recent logs
sudo journalctl -u ai-sysadmin-agent -n 50

# Check if ports are listening
sudo netstat -tlnp | grep -E ':(8080|8081|8082)'
```

### Check Resource Usage
```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check CPU usage
top -bn1 | grep "Cpu(s)"
```

## 🚨 Common Issues

### 1. Service Won't Start

**Symptoms:**
- `systemctl status` shows failed
- Service keeps restarting
- No response from web interface

**Solutions:**

1. **Check logs for errors:**
   ```bash
   sudo journalctl -u ai-sysadmin-agent -f
   ```

2. **Verify Python environment:**
   ```bash
   cd /home/inggo/ai-agent
   source ai-agent-env/bin/activate
   python --version
   pip list | grep -E "(autogen|llama-cpp|fastapi)"
   ```

3. **Check model file:**
   ```bash
   ls -la /home/inggo/ai-agent/models/
   file /home/inggo/ai-agent/models/qwen2-1.5b-q4_k_m.gguf
   ```

4. **Recreate virtual environment:**
   ```bash
   cd /home/inggo/ai-agent
   rm -rf ai-agent-env
   python3 -m venv ai-agent-env
   source ai-agent-env/bin/activate
   pip install -r requirements.txt
   ```

### 2. Model Loading Errors

**Symptoms:**
- "Model file not found" errors
- "Failed to load model" messages
- High memory usage during startup

**Solutions:**

1. **Verify model file exists and is valid:**
   ```bash
   ls -la /home/inggo/ai-agent/models/qwen2-1.5b-q4_k_m.gguf
   # Should show a file around 1-2GB
   ```

2. **Re-download the model:**
   ```bash
   cd /home/inggo/ai-agent
   source ai-agent-env/bin/activate
   ./scripts/setup_model.sh
   ```

3. **Test model loading manually:**
   ```bash
   cd /home/inggo/ai-agent
   source ai-agent-env/bin/activate
   python3 -c "
   from llama_cpp import Llama
   llm = Llama('models/qwen2-1.5b-q4_k_m.gguf', n_ctx=512, verbose=True)
   print('Model loaded successfully')
   "
   ```

4. **Check available memory:**
   ```bash
   free -h
   # Need at least 2GB free for model loading
   ```

### 3. Web Interface Not Accessible

**Symptoms:**
- Browser shows "connection refused"
- Port 8080 not responding
- Firewall blocking access

**Solutions:**

1. **Check if the service is listening:**
   ```bash
   sudo netstat -tlnp | grep :8080
   # Should show python process listening on 0.0.0.0:8080
   ```

2. **Check firewall settings:**
   ```bash
   sudo ufw status
   sudo ufw allow 8080/tcp
   ```

3. **Test local access:**
   ```bash
   curl http://localhost:8080/health
   # Should return JSON with status
   ```

4. **Check for port conflicts:**
   ```bash
   sudo lsof -i :8080
   # Kill conflicting processes if found
   ```

### 4. High Memory Usage

**Symptoms:**
- System becomes slow
- Out of memory errors
- Agent crashes

**Solutions:**

1. **Monitor memory usage:**
   ```bash
   htop
   # Look for python processes using high memory
   ```

2. **Reduce model context length:**
   ```bash
   # Edit config/agent.yaml
   nano /home/inggo/ai-agent/config/agent.yaml
   # Change context_length from 2048 to 1024
   ```

3. **Add swap space:**
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

4. **Restart the service:**
   ```bash
   sudo systemctl restart ai-sysadmin-agent
   ```

### 5. Command Execution Failures

**Symptoms:**
- Commands are blocked
- "Permission denied" errors
- Commands not found

**Solutions:**

1. **Check command whitelist:**
   ```bash
   # Edit config/security.yaml
   nano /home/inggo/ai-agent/config/security.yaml
   # Add missing commands to allowed list
   ```

2. **Check file permissions:**
   ```bash
   sudo chown -R inggo:inggo /home/inggo/ai-agent
   chmod +x /home/inggo/ai-agent/scripts/*.sh
   ```

3. **Test command manually:**
   ```bash
   # Test if command works for the user
   su - inggo -c "df -h"
   ```

4. **Check sudo permissions:**
   ```bash
   sudo -l
   # Verify inggo user has necessary sudo permissions
   ```

### 6. Slow Response Times

**Symptoms:**
- Long delays in responses
- Timeout errors
- High CPU usage

**Solutions:**

1. **Check system load:**
   ```bash
   uptime
   # Load average should be < number of CPU cores
   ```

2. **Optimize model settings:**
   ```bash
   # Edit config/agent.yaml
   nano /home/inggo/ai-agent/config/agent.yaml
   # Reduce max_tokens and context_length
   ```

3. **Check for background processes:**
   ```bash
   ps aux | grep -E "(python|llama)"
   # Kill unnecessary processes
   ```

4. **Restart with fresh memory:**
   ```bash
   sudo systemctl restart ai-sysadmin-agent
   ```

## 🔧 Advanced Troubleshooting

### Enable Debug Logging

1. **Edit the service file:**
   ```bash
   sudo systemctl edit ai-sysadmin-agent
   ```

2. **Add debug environment:**
   ```ini
   [Service]
   Environment=LOG_LEVEL=DEBUG
   Environment=PYTHONPATH=/home/inggo/ai-agent
   ```

3. **Restart the service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart ai-sysadmin-agent
   ```

### Manual Testing

1. **Test the agent directly:**
   ```bash
   cd /home/inggo/ai-agent
   source ai-agent-env/bin/activate
   python -m src.main
   ```

2. **Test individual components:**
   ```bash
   # Test model loading
   python3 -c "from llama_cpp import Llama; Llama('models/qwen2-1.5b-q4_k_m.gguf')"
   
   # Test command validation
   python3 -c "from src.security.command_validator import CommandValidator; print('OK')"
   
   # Test web interface
   python3 -c "from src.interfaces.web import WebInterface; print('OK')"
   ```

### Performance Profiling

1. **Monitor system resources:**
   ```bash
   # Install monitoring tools
   sudo apt install htop iotop nethogs
   
   # Monitor in real-time
   htop
   iotop
   nethogs
   ```

2. **Check disk I/O:**
   ```bash
   sudo iotop -o
   # Look for high disk usage
   ```

3. **Monitor network:**
   ```bash
   sudo nethogs
   # Check network usage
   ```

## 📞 Getting Help

### Collect Debug Information

Before asking for help, collect this information:

```bash
# System information
uname -a
free -h
df -h
systemctl status ai-sysadmin-agent

# Service logs
sudo journalctl -u ai-sysadmin-agent -n 100

# Configuration
cat /home/inggo/ai-agent/config/agent.yaml
cat /home/inggo/ai-agent/config/security.yaml

# Python environment
cd /home/inggo/ai-agent
source ai-agent-env/bin/activate
pip list
python --version
```

### Common Error Messages

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| "Model file not found" | Model not downloaded | Run `./scripts/setup_model.sh` |
| "Permission denied" | File permissions | `sudo chown -R inggo:inggo /home/inggo/ai-agent` |
| "Port already in use" | Another service using port | `sudo lsof -i :8080` and kill process |
| "Out of memory" | Insufficient RAM | Add swap or reduce model size |
| "Command blocked" | Security policy | Add command to whitelist |
| "Connection refused" | Service not running | `sudo systemctl start ai-sysadmin-agent` |

### Support Channels

- **GitHub Issues**: [Create an issue](https://github.com/your-username/ai-sysadmin-agent/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/your-username/ai-sysadmin-agent/discussions)
- **Documentation**: [Wiki](https://github.com/your-username/ai-sysadmin-agent/wiki)

## 🔄 Recovery Procedures

### Complete Reinstallation

If all else fails, you can completely reinstall:

```bash
# Stop and remove service
sudo systemctl stop ai-sysadmin-agent
sudo systemctl disable ai-sysadmin-agent
sudo rm /etc/systemd/system/ai-sysadmin-agent.service

# Remove project directory
sudo rm -rf /home/inggo/ai-agent

# Reinstall
git clone https://github.com/your-username/ai-sysadmin-agent.git /home/inggo/ai-agent
cd /home/inggo/ai-agent
./scripts/install.sh
```

### Backup and Restore

1. **Create backup:**
   ```bash
   tar -czf ai-agent-backup-$(date +%Y%m%d).tar.gz /home/inggo/ai-agent
   ```

2. **Restore from backup:**
   ```bash
   sudo systemctl stop ai-sysadmin-agent
   sudo rm -rf /home/inggo/ai-agent
   tar -xzf ai-agent-backup-YYYYMMDD.tar.gz -C /
   sudo systemctl start ai-sysadmin-agent
   ```

Remember: Always backup your configuration files before making changes!
