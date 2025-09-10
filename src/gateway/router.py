"""
API Gateway Router for Dual-Model AI System Administrator Agent
Routes queries between Gemma 2 and DeepSeek-R1 Distill models
"""

import asyncio
import json
import logging
from typing import Dict, Any, Optional
from datetime import datetime

import httpx
import structlog
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Request/Response Models
class ChatRequest(BaseModel):
    message: str = Field(..., description="User message/query")
    model: Optional[str] = Field(None, description="Specific model to use (gemma2, deepseek, auto)")
    stream: bool = Field(False, description="Enable streaming response")
    context: Optional[Dict[str, Any]] = Field(None, description="Additional context")

class ChatResponse(BaseModel):
    response: str
    model_used: str
    timestamp: datetime
    processing_time: float
    tokens_used: Optional[int] = None

class ModelStatus(BaseModel):
    name: str
    status: str
    url: str
    model_id: str
    last_health_check: datetime

class GatewayStatus(BaseModel):
    status: str
    models: Dict[str, ModelStatus]
    uptime: float
    total_requests: int
    requests_by_model: Dict[str, int]

class APIGateway:
    """API Gateway for routing queries between AI models"""
    
    def __init__(self):
        self.app = FastAPI(
            title="AI System Administrator Gateway",
            description="Dynamic routing between Gemma 2 and DeepSeek-R1 Distill models",
            version="2.0.0"
        )
        
        # Model configurations
        self.models = {
            "gemma2": {
                "name": "Gemma 2",
                "url": "http://ollama-gemma2:11434",
                "model_id": "gemma2:2b",
                "description": "Google's Gemma 2 (2B parameters) - Best for general system administration",
                "strengths": ["General tasks", "Code generation", "System monitoring", "Troubleshooting"]
            },
            "deepseek": {
                "name": "DeepSeek-R1 Distill",
                "url": "http://ollama-deepseek:11434", 
                "model_id": "deepseek-r1-distill:1.5b",
                "description": "DeepSeek-R1 Distill (1.5B parameters) - Best for reasoning and analysis",
                "strengths": ["Complex reasoning", "Problem analysis", "Decision making", "Root cause analysis"]
            }
        }
        
        # Statistics
        self.stats = {
            "total_requests": 0,
            "requests_by_model": {"gemma2": 0, "deepseek": 0},
            "start_time": datetime.now()
        }
        
        # Setup routes
        self._setup_routes()
        
    def _setup_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {"status": "healthy", "timestamp": datetime.now()}
        
        @self.app.get("/status", response_model=GatewayStatus)
        async def get_status():
            """Get gateway and model status"""
            model_statuses = {}
            
            for model_id, config in self.models.items():
                try:
                    async with httpx.AsyncClient(timeout=5.0) as client:
                        response = await client.get(f"{config['url']}/api/tags")
                        status = "healthy" if response.status_code == 200 else "unhealthy"
                except Exception:
                    status = "unhealthy"
                
                model_statuses[model_id] = ModelStatus(
                    name=config["name"],
                    status=status,
                    url=config["url"],
                    model_id=config["model_id"],
                    last_health_check=datetime.now()
                )
            
            uptime = (datetime.now() - self.stats["start_time"]).total_seconds()
            
            return GatewayStatus(
                status="healthy",
                models=model_statuses,
                uptime=uptime,
                total_requests=self.stats["total_requests"],
                requests_by_model=self.stats["requests_by_model"]
            )
        
        @self.app.get("/models")
        async def list_models():
            """List available models and their capabilities"""
            return {
                "models": {
                    model_id: {
                        "name": config["name"],
                        "description": config["description"],
                        "strengths": config["strengths"],
                        "status": "available"
                    }
                    for model_id, config in self.models.items()
                }
            }
        
        @self.app.post("/chat", response_model=ChatResponse)
        async def chat(request: ChatRequest):
            """Main chat endpoint with dynamic model routing"""
            start_time = datetime.now()
            
            # Determine which model to use
            model_id = self._select_model(request.model, request.message)
            
            # Update statistics
            self.stats["total_requests"] += 1
            self.stats["requests_by_model"][model_id] += 1
            
            logger.info("Processing chat request", 
                       model=model_id, 
                       message_length=len(request.message),
                       user_model_preference=request.model)
            
            try:
                if request.stream:
                    return StreamingResponse(
                        self._stream_response(model_id, request.message),
                        media_type="text/plain"
                    )
                else:
                    response_text = await self._get_response(model_id, request.message)
                    
                    processing_time = (datetime.now() - start_time).total_seconds()
                    
                    return ChatResponse(
                        response=response_text,
                        model_used=model_id,
                        timestamp=datetime.now(),
                        processing_time=processing_time
                    )
                    
            except Exception as e:
                logger.error("Error processing chat request", error=str(e), model=model_id)
                raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}")
        
        @self.app.post("/chat/{model_id}")
        async def chat_with_model(model_id: str, request: ChatRequest):
            """Chat with a specific model"""
            if model_id not in self.models:
                raise HTTPException(status_code=404, detail=f"Model {model_id} not found")
            
            # Override model selection
            request.model = model_id
            return await chat(request)
        
        @self.app.get("/")
        async def root():
            """Root endpoint with API information"""
            return {
                "service": "AI System Administrator Gateway",
                "version": "2.0.0",
                "models": list(self.models.keys()),
                "endpoints": {
                    "chat": "/chat",
                    "status": "/status", 
                    "models": "/models",
                    "health": "/health"
                }
            }
    
    def _select_model(self, user_preference: Optional[str], message: str) -> str:
        """Select the best model for the given request"""
        
        # If user specified a model, use it
        if user_preference and user_preference in self.models:
            return user_preference
        
        # Auto-selection based on message content
        message_lower = message.lower()
        
        # Keywords that suggest DeepSeek-R1 is better
        deepseek_keywords = [
            "analyze", "analysis", "why", "reason", "cause", "problem", "issue",
            "debug", "troubleshoot", "investigate", "compare", "decision",
            "complex", "difficult", "challenging", "error", "failure"
        ]
        
        # Keywords that suggest Gemma 2 is better  
        gemma_keywords = [
            "show", "list", "display", "get", "check", "status", "monitor",
            "create", "generate", "write", "script", "command", "install",
            "configure", "setup", "simple", "quick", "basic"
        ]
        
        deepseek_score = sum(1 for keyword in deepseek_keywords if keyword in message_lower)
        gemma_score = sum(1 for keyword in gemma_keywords if keyword in message_lower)
        
        # Default to Gemma 2 for general tasks
        if deepseek_score > gemma_score:
            return "deepseek"
        else:
            return "gemma2"
    
    async def _get_response(self, model_id: str, message: str) -> str:
        """Get response from specified model"""
        config = self.models[model_id]
        
        payload = {
            "model": config["model_id"],
            "prompt": message,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 2048
            }
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{config['url']}/api/generate",
                json=payload
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("response", "No response generated")
    
    async def _stream_response(self, model_id: str, message: str):
        """Stream response from specified model"""
        config = self.models[model_id]
        
        payload = {
            "model": config["model_id"],
            "prompt": message,
            "stream": True,
            "options": {
                "temperature": 0.7,
                "top_p": 0.9,
                "max_tokens": 2048
            }
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream(
                "POST",
                f"{config['url']}/api/generate",
                json=payload
            ) as response:
                response.raise_for_status()
                
                async for line in response.aiter_lines():
                    if line.strip():
                        try:
                            data = json.loads(line)
                            if "response" in data:
                                yield data["response"]
                        except json.JSONDecodeError:
                            continue

# Create FastAPI app instance
gateway = APIGateway()
app = gateway.app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
