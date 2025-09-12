#!/usr/bin/env python3
"""
Simple CLI Chat Interface for AI System Administrator Agent
Provides an interactive terminal interface to chat with Gemma 3 and DeepSeek-R1 models
"""

import asyncio
import json
import sys
from typing import Optional
import httpx
import argparse

class AIChatCLI:
    def __init__(self, api_url: str = "http://localhost:4000"):
        self.api_url = api_url
        self.session = httpx.AsyncClient(timeout=120.0)
        
    async def chat(self, message: str, model: Optional[str] = None) -> str:
        """Send a chat message to the API Gateway"""
        payload = {
            "message": message,
            "stream": False
        }
        
        if model:
            payload["model"] = model
            
        try:
            response = await self.session.post(
                f"{self.api_url}/chat",
                json=payload
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("response", "No response generated")
            
        except httpx.HTTPStatusError as e:
            return f"HTTP Error {e.response.status_code}: {e.response.text}"
        except Exception as e:
            return f"Error: {str(e)}"
    
    async def get_models(self) -> dict:
        """Get available models"""
        try:
            response = await self.session.get(f"{self.api_url}/models")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    async def health_check(self) -> bool:
        """Check if the API Gateway is healthy"""
        try:
            response = await self.session.get(f"{self.api_url}/health")
            return response.status_code == 200
        except:
            return False
    
    async def interactive_chat(self):
        """Start interactive chat session"""
        print("🤖 AI System Administrator Agent - CLI Chat")
        print("=" * 50)
        
        # Check health
        if not await self.health_check():
            print("❌ API Gateway is not accessible. Please check if the service is running.")
            return
        
        # Get available models
        models_info = await self.get_models()
        if "error" in models_info:
            print(f"❌ Error getting models: {models_info['error']}")
            return
        
        print("✅ Connected to API Gateway")
        print("\nAvailable models:")
        for model_id, info in models_info.get("models", {}).items():
            print(f"  • {model_id}: {info.get('name', 'Unknown')}")
        
        print("\nCommands:")
        print("  /help     - Show this help")
        print("  /models   - List available models")
        print("  /model <name> - Switch to specific model (qwen3)")
        print("  /auto     - Use automatic model selection")
        print("  /quit     - Exit the chat")
        print("\nStart chatting! (Type your message and press Enter)")
        print("-" * 50)
        
        current_model = None
        
        while True:
            try:
                # Get user input
                user_input = input("\n💬 You: ").strip()
                
                if not user_input:
                    continue
                
                # Handle commands
                if user_input.startswith('/'):
                    if user_input == '/quit':
                        print("👋 Goodbye!")
                        break
                    elif user_input == '/help':
                        print("\nCommands:")
                        print("  /help     - Show this help")
                        print("  /models   - List available models")
                        print("  /model <name> - Switch to specific model (qwen3)")
                        print("  /auto     - Use automatic model selection")
                        print("  /quit     - Exit the chat")
                        continue
                    elif user_input == '/models':
                        models_info = await self.get_models()
                        print("\nAvailable models:")
                        for model_id, info in models_info.get("models", {}).items():
                            status = "✅" if current_model == model_id else "⚪"
                            print(f"  {status} {model_id}: {info.get('name', 'Unknown')}")
                        continue
                    elif user_input.startswith('/model '):
                        model_name = user_input[7:].strip()
                        if model_name in ['qwen3']:
                            current_model = model_name
                            print(f"✅ Switched to {model_name}")
                        else:
                            print("❌ Invalid model. Use 'qwen3'")
                        continue
                    elif user_input == '/auto':
                        current_model = None
                        print("✅ Using automatic model selection")
                        continue
                    else:
                        print("❌ Unknown command. Type /help for available commands.")
                        continue
                
                # Show current model
                model_display = f" ({current_model})" if current_model else " (auto)"
                print(f"🤖 Agent{model_display}: ", end="", flush=True)
                
                # Send message and get response
                response = await self.chat(user_input, current_model)
                print(response)
                
            except KeyboardInterrupt:
                print("\n\n👋 Goodbye!")
                break
            except EOFError:
                print("\n\n👋 Goodbye!")
                break
            except Exception as e:
                print(f"\n❌ Error: {str(e)}")
    
    async def single_chat(self, message: str, model: Optional[str] = None):
        """Send a single message and get response"""
        if not await self.health_check():
            print("❌ API Gateway is not accessible. Please check if the service is running.")
            return
        
        print(f"💬 You: {message}")
        print("🤖 Agent: ", end="", flush=True)
        
        response = await self.chat(message, model)
        print(response)
    
    async def close(self):
        """Close the session"""
        await self.session.aclose()

async def main():
    parser = argparse.ArgumentParser(description="AI System Administrator Agent CLI")
    parser.add_argument("--url", default="http://localhost:4000", help="API Gateway URL")
    parser.add_argument("--model", choices=["qwen3"], help="Specific model to use")
    parser.add_argument("message", nargs="*", help="Message to send (if not provided, starts interactive mode)")
    
    args = parser.parse_args()
    
    chat = AIChatCLI(args.url)
    
    try:
        if args.message:
            # Single message mode
            message = " ".join(args.message)
            await chat.single_chat(message, args.model)
        else:
            # Interactive mode
            await chat.interactive_chat()
    finally:
        await chat.close()

if __name__ == "__main__":
    asyncio.run(main())
