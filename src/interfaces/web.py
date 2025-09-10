"""
Web Interface - Web-based interface for the AI System Administrator Agent
"""

import asyncio
import json
import logging
from typing import Dict, Any, List
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from src.agent.sysadmin_agent import SysAdminAgent

logger = logging.getLogger(__name__)


class WebInterface:
    """Web-based interface for the AI System Administrator Agent."""
    
    def __init__(self, agent: SysAdminAgent, config: Dict[str, Any]):
        """Initialize the web interface."""
        self.agent = agent
        self.config = config
        self.app = FastAPI(
            title="AI System Administrator Agent",
            description="Web interface for AI-powered system administration",
            version="1.0.0"
        )
        
        # WebSocket connection manager
        self.active_connections: List[WebSocket] = []
        
        # Setup routes and middleware
        self._setup_middleware()
        self._setup_routes()
    
    def _setup_middleware(self):
        """Setup FastAPI middleware."""
        # CORS middleware
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],  # In production, specify actual origins
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    
    def _setup_routes(self):
        """Setup FastAPI routes."""
        
        @self.app.get("/")
        async def root():
            """Serve the main web interface."""
            return HTMLResponse(self._get_html_interface())
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint."""
            return {"status": "healthy", "agent": self.agent.get_status()}
        
        @self.app.post("/api/chat")
        async def chat_endpoint(request: dict):
            """Chat API endpoint."""
            try:
                user_input = request.get("message", "").strip()
                if not user_input:
                    raise HTTPException(status_code=400, detail="Empty message")
                
                response = await self.agent.process_request(user_input)
                return {"response": response, "status": "success"}
                
            except Exception as e:
                logger.error(f"Chat endpoint error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/api/status")
        async def status_endpoint():
            """Status API endpoint."""
            return self.agent.get_status()
        
        @self.app.websocket("/ws")
        async def websocket_endpoint(websocket: WebSocket):
            """WebSocket endpoint for real-time communication."""
            await self._handle_websocket(websocket)
    
    async def _handle_websocket(self, websocket: WebSocket):
        """Handle WebSocket connections."""
        await websocket.accept()
        self.active_connections.append(websocket)
        
        try:
            # Send welcome message
            await websocket.send_text(json.dumps({
                "type": "welcome",
                "message": "Connected to AI System Administrator Agent"
            }))
            
            while True:
                # Receive message
                data = await websocket.receive_text()
                message = json.loads(data)
                
                if message.get("type") == "chat":
                    user_input = message.get("message", "").strip()
                    if user_input:
                        # Process request
                        response = await self.agent.process_request(user_input)
                        
                        # Send response
                        await websocket.send_text(json.dumps({
                            "type": "response",
                            "message": response
                        }))
                
        except WebSocketDisconnect:
            self.active_connections.remove(websocket)
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
            if websocket in self.active_connections:
                self.active_connections.remove(websocket)
    
    def _get_html_interface(self) -> str:
        """Get the HTML interface."""
        return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI System Administrator Agent</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            width: 90%;
            max-width: 800px;
            height: 80vh;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2rem;
            margin-bottom: 10px;
        }
        
        .header p {
            opacity: 0.9;
            font-size: 1.1rem;
        }
        
        .chat-container {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        
        .messages {
            flex: 1;
            padding: 20px;
            overflow-y: auto;
            background: #f8f9fa;
        }
        
        .message {
            margin-bottom: 15px;
            padding: 15px;
            border-radius: 15px;
            max-width: 80%;
            word-wrap: break-word;
        }
        
        .message.user {
            background: #007bff;
            color: white;
            margin-left: auto;
            text-align: right;
        }
        
        .message.agent {
            background: white;
            border: 1px solid #e9ecef;
            margin-right: auto;
        }
        
        .message.system {
            background: #28a745;
            color: white;
            text-align: center;
            margin: 0 auto;
            max-width: 60%;
        }
        
        .input-container {
            padding: 20px;
            background: white;
            border-top: 1px solid #e9ecef;
        }
        
        .input-group {
            display: flex;
            gap: 10px;
        }
        
        .input-group input {
            flex: 1;
            padding: 15px;
            border: 2px solid #e9ecef;
            border-radius: 25px;
            font-size: 1rem;
            outline: none;
            transition: border-color 0.3s;
        }
        
        .input-group input:focus {
            border-color: #007bff;
        }
        
        .input-group button {
            padding: 15px 25px;
            background: #007bff;
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 1rem;
            transition: background 0.3s;
        }
        
        .input-group button:hover {
            background: #0056b3;
        }
        
        .input-group button:disabled {
            background: #6c757d;
            cursor: not-allowed;
        }
        
        .status {
            padding: 10px 20px;
            background: #e9ecef;
            font-size: 0.9rem;
            color: #6c757d;
            text-align: center;
        }
        
        .typing {
            display: none;
            padding: 10px 20px;
            color: #6c757d;
            font-style: italic;
        }
        
        @media (max-width: 600px) {
            .container {
                width: 95%;
                height: 90vh;
            }
            
            .header h1 {
                font-size: 1.5rem;
            }
            
            .message {
                max-width: 95%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🤖 AI System Administrator Agent</h1>
            <p>Your AI-powered Linux system administration assistant</p>
        </div>
        
        <div class="chat-container">
            <div class="messages" id="messages">
                <div class="message system">
                    Welcome! I'm your AI system administrator. Ask me to help with Linux tasks like checking disk usage, managing services, or monitoring system resources.
                </div>
            </div>
            
            <div class="typing" id="typing">
                Agent is typing...
            </div>
            
            <div class="input-container">
                <div class="input-group">
                    <input type="text" id="messageInput" placeholder="Ask me to help with system administration..." autocomplete="off">
                    <button id="sendButton" onclick="sendMessage()">Send</button>
                </div>
            </div>
        </div>
        
        <div class="status" id="status">
            Connecting...
        </div>
    </div>

    <script>
        let ws;
        let isConnected = false;
        
        function connectWebSocket() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${protocol}//${window.location.host}/ws`;
            
            ws = new WebSocket(wsUrl);
            
            ws.onopen = function() {
                isConnected = true;
                updateStatus('Connected');
                console.log('WebSocket connected');
            };
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                
                if (data.type === 'welcome') {
                    addMessage(data.message, 'system');
                } else if (data.type === 'response') {
                    hideTyping();
                    addMessage(data.message, 'agent');
                }
            };
            
            ws.onclose = function() {
                isConnected = false;
                updateStatus('Disconnected');
                console.log('WebSocket disconnected');
                
                // Try to reconnect after 3 seconds
                setTimeout(connectWebSocket, 3000);
            };
            
            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
                updateStatus('Connection error');
            };
        }
        
        function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            
            if (!message || !isConnected) return;
            
            // Add user message to chat
            addMessage(message, 'user');
            input.value = '';
            
            // Show typing indicator
            showTyping();
            
            // Send message via WebSocket
            ws.send(JSON.stringify({
                type: 'chat',
                message: message
            }));
        }
        
        function addMessage(text, type) {
            const messages = document.getElementById('messages');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${type}`;
            messageDiv.textContent = text;
            messages.appendChild(messageDiv);
            messages.scrollTop = messages.scrollHeight;
        }
        
        function showTyping() {
            document.getElementById('typing').style.display = 'block';
        }
        
        function hideTyping() {
            document.getElementById('typing').style.display = 'none';
        }
        
        function updateStatus(status) {
            document.getElementById('status').textContent = status;
        }
        
        // Event listeners
        document.getElementById('messageInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
        
        // Connect on page load
        connectWebSocket();
    </script>
</body>
</html>
        """
    
    async def start(self):
        """Start the web interface."""
        web_config = self.config.get('interfaces', {}).get('web', {})
        host = web_config.get('host', '0.0.0.0')
        port = web_config.get('port', 8080)
        
        logger.info(f"Starting web interface on {host}:{port}")
        
        # Start the server
        config = uvicorn.Config(
            app=self.app,
            host=host,
            port=port,
            log_level="info"
        )
        server = uvicorn.Server(config)
        await server.serve()
    
    async def run(self):
        """Run the web interface (for compatibility with main loop)."""
        await self.start()
