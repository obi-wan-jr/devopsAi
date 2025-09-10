# AI Agent Quick Reference

## 🚀 Quick Access
- **📚 Documentation**: `http://meatpi:3004`
- **🌐 API Gateway**: `http://meatpi:8080`
- **Health Check**: `http://meatpi:8080/health`
- **Gemma 3 Direct**: `http://meatpi:11434`
- **DeepSeek-R1 Direct**: `http://meatpi:11435`

## 🤖 Model Selection
- **Gemma 3 (1B)**: Fast, general tasks, monitoring, scripts
- **DeepSeek-R1 (1.5B)**: Complex analysis, troubleshooting, reasoning

## 📝 Common Commands

### Test Setup
```bash
curl http://meatpi:8080/health
curl -X POST http://meatpi:8080/chat -H "Content-Type: application/json" -d '{"message": "Hello"}'
```

### System Check
```bash
curl -X POST http://meatpi:8080/chat -H "Content-Type: application/json" -d '{"message": "Show me system status"}'
```

### Docker Management
```bash
curl -X POST http://meatpi:8080/chat -H "Content-Type: application/json" -d '{"message": "List Docker containers"}'
```

### Force Specific Model
```bash
# Gemma 3
curl -X POST http://meatpi:8080/chat/gemma3 -H "Content-Type: application/json" -d '{"message": "Your query"}'

# DeepSeek-R1
curl -X POST http://meatpi:8080/chat/deepseek -H "Content-Type: application/json" -d '{"message": "Your query"}'
```

## 🔧 Management
```bash
# Check status
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.dual-models.yml ps'

# Restart services
ssh inggo@meatpi 'cd /home/inggo/ai-agent && docker-compose -f docker-compose.dual-models.yml restart'

# View logs
ssh inggo@meatpi 'docker logs api-gateway'
```

## 💡 Tips
- Use **Gemma 3** for quick tasks
- Use **DeepSeek-R1** for complex analysis
- Let API Gateway auto-select for best results
- Be specific in your questions
- Mention your system context (Pi 5, Ubuntu, etc.)
