"""
API Gateway Router for Remote LLM AI System Administrator Agent
Routes queries to remote Qwen3-4B-Thinking service
"""

import asyncio
import json
import logging
import os
import time
from collections import defaultdict
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

import httpx
import structlog
from fastapi import FastAPI, HTTPException, Request, Header, Depends
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import APIKeyHeader
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
            description="Dynamic routing between Gemma 3 and DeepSeek-R1 models",
            version="2.0.0"
        )
        
        # Security configuration
        self.api_key = os.getenv("API_KEY")  # Optional API key for authentication
        self.allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3004,http://localhost:8080,http://127.0.0.1:3004,http://127.0.0.1:8080").split(",")

        # Rate limiting (requests per minute per IP)
        self.rate_limit_per_minute = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))
        self.rate_limit_window = timedelta(minutes=1)
        self.request_counts = defaultdict(list)  # IP -> list of timestamps

        # API Key security scheme
        self.api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

        # Add CORS middleware with configurable origins
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=self.allowed_origins,
            allow_credentials=True,
            allow_methods=["GET", "POST", "OPTIONS"],
            allow_headers=["*"],
        )
        
        # Model configurations - Using remote LLM service
        remote_llm_url = os.getenv("REMOTE_LLM_URL", "http://100.79.227.126:1234")
        remote_llm_model = os.getenv("REMOTE_LLM_MODEL", "qwen/qwen3-4b-thinking-2507")

        self.models = {
            "qwen3": {
                "name": "Qwen3-4B-Thinking",
                "url": remote_llm_url,
                "model_id": remote_llm_model,
                "description": f"Qwen3-4B-Thinking - Advanced reasoning model for complex system administration tasks hosted at {remote_llm_url}",
                "strengths": ["Advanced reasoning", "Complex problem solving", "System analysis", "Decision making", "Root cause analysis", "Code generation"]
            }
        }
        
        # Statistics
        self.stats = {
            "total_requests": 0,
            "requests_by_model": {"qwen3": 0},
            "start_time": datetime.now()
        }
        
        # Setup routes
        self._setup_routes()

    async def _authenticate(self, api_key: str = Depends(APIKeyHeader(name="X-API-Key", auto_error=False))):
        """Optional API key authentication"""
        if self.api_key and api_key != self.api_key:
            raise HTTPException(status_code=401, detail="Invalid API key")
        return True

    async def _check_rate_limit(self, request: Request):
        """Simple rate limiting per IP"""
        client_ip = request.client.host
        now = datetime.now()

        # Clean old timestamps
        self.request_counts[client_ip] = [
            ts for ts in self.request_counts[client_ip]
            if now - ts < self.rate_limit_window
        ]

        # Check if over limit
        if len(self.request_counts[client_ip]) >= self.rate_limit_per_minute:
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded. Maximum {self.rate_limit_per_minute} requests per minute."
            )

        # Add current request
        self.request_counts[client_ip].append(now)
        
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
                        response = await client.get(f"{config['url']}/v1/models")
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
        async def chat(request: ChatRequest, req: Request, auth: bool = Depends(self._authenticate)):
            """Main chat endpoint with dynamic model routing"""
            # Check rate limit
            await self._check_rate_limit(req)

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
            print(f"DEBUG: Processing chat request for model {model_id}")
            
            try:
                if request.stream:
                    return StreamingResponse(
                        self._stream_response(model_id, request.message),
                        media_type="text/plain"
                    )
                else:
                    logger.info("Attempting to get response", model=model_id, message_preview=request.message[:50])
                    response_text = await self._get_response(model_id, request.message)
                    
                    processing_time = (datetime.now() - start_time).total_seconds()
                    
                    logger.info("Response received", model=model_id, response_length=len(response_text))
                    
                    return ChatResponse(
                        response=response_text,
                        model_used=model_id,
                        timestamp=datetime.now(),
                        processing_time=processing_time
                    )
                    
            except Exception as e:
                error_msg = str(e) if str(e) else "Unknown error"
                logger.error("Error processing chat request", error=error_msg, model=model_id, exc_info=True)
                print(f"DEBUG: Exception caught: {type(e).__name__}: {error_msg}")
                raise HTTPException(status_code=500, detail=f"Error processing request: {error_msg}")
        
        @self.app.post("/chat/{model_id}")
        async def chat_with_model(model_id: str, request: ChatRequest, req: Request, auth: bool = Depends(self._authenticate)):
            """Chat with a specific model"""
            # Check rate limit
            await self._check_rate_limit(req)

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
        
        @self.app.get("/{model_id}/models")
        async def get_model_info(model_id: str):
            """Get information about a specific model"""
            if model_id not in self.models:
                raise HTTPException(status_code=404, detail=f"Model {model_id} not found")
            
            config = self.models[model_id]
            
            # Get model list from remote LLM service
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.get(f"{config['url']}/v1/models")
                    response.raise_for_status()
                    models_data = response.json()
                    
                return {
                    "model_id": model_id,
                    "name": config["name"],
                    "description": config["description"],
                    "available_models": models_data.get("data", []),
                    "status": "available"
                }
            except Exception as e:
                return {
                    "model_id": model_id,
                    "name": config["name"],
                    "description": config["description"],
                    "available_models": [],
                    "status": "error",
                    "error": str(e)
                }
    
    def _select_model(self, user_preference: Optional[str], message: str) -> str:
        """Select the best model for the given request"""
        
        # If user specified a model, use it (if available)
        if user_preference and user_preference in self.models:
            return user_preference
        
        # Since we only have one model (Qwen3-4B-Thinking), always use it
        # This model is capable of handling all types of system administration tasks
        return "qwen3"
    
    async def _get_response(self, model_id: str, message: str) -> str:
        """Get response from specified model"""
        config = self.models[model_id]
        
        payload = {
            "model": config["model_id"],
            "messages": [
                {
                    "role": "user",
                    "content": message
                }
            ],
            "max_tokens": 1024,
            "temperature": 0.7,
            "top_p": 0.9
        }
        
        logger.info("Sending request to remote LLM", model=model_id, url=config["url"], model_id=config["model_id"])
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            try:
                response = await client.post(
                    f"{config['url']}/v1/chat/completions",
                    json=payload
                )
                logger.info("Remote LLM response received", status_code=response.status_code)
                response.raise_for_status()
                
                result = response.json()
                logger.info("Response parsed successfully", response_length=len(result.get("choices", [{}])[0].get("message", {}).get("content", "")))
                
                # Extract response from OpenAI-compatible format
                if "choices" in result and len(result["choices"]) > 0:
                    message = result["choices"][0]["message"]
                    # Qwen3-4B-Thinking puts response in reasoning_content if content is empty
                    if message.get("content"):
                        return message["content"]
                    elif message.get("reasoning_content"):
                        return message["reasoning_content"]
                    else:
                        return "No response generated"
                else:
                    return "No response generated"
            except httpx.HTTPStatusError as e:
                logger.error("HTTP error from remote LLM", status_code=e.response.status_code, response_text=e.response.text[:200])
                raise
            except Exception as e:
                logger.error("Unexpected error in _get_response", error=str(e), exc_info=True)
                raise
    
    async def _stream_response(self, model_id: str, message: str):
        """Stream response from specified model"""
        config = self.models[model_id]
        
        payload = {
            "model": config["model_id"],
            "messages": [
                {
                    "role": "user",
                    "content": message
                }
            ],
            "max_tokens": 1024,
            "temperature": 0.7,
            "top_p": 0.9,
            "stream": True
        }
        
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                f"{config['url']}/v1/chat/completions",
                json=payload
            ) as response:
                response.raise_for_status()
                
                async for line in response.aiter_lines():
                    if line.strip() and line.startswith("data: "):
                        try:
                            data = json.loads(line[6:])  # Remove "data: " prefix
                            if "choices" in data and len(data["choices"]) > 0:
                                delta = data["choices"][0].get("delta", {})
                                # Handle both content and reasoning_content
                                if "content" in delta:
                                    yield delta["content"]
                                elif "reasoning_content" in delta:
                                    yield delta["reasoning_content"]
                        except json.JSONDecodeError:
                            continue

# Create FastAPI app instance
gateway = APIGateway()
app = gateway.app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
