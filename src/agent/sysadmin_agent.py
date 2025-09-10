"""
AI System Administrator Agent - Core Agent Implementation
"""

import asyncio
import logging
import re
from typing import Dict, List, Optional, Any
from pathlib import Path

import autogen
from llama_cpp import Llama

from src.security.command_validator import CommandValidator
from src.security.audit_logger import AuditLogger
from src.utils.system_executor import SystemExecutor

logger = logging.getLogger(__name__)


class SysAdminAgent:
    """AI System Administrator Agent using AutoGen and Qwen2."""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize the system administrator agent."""
        self.config = config
        self.agent_config = config['agent']
        self.model_config = self.agent_config['model']
        
        # Initialize components
        self.llm = None
        self.autogen_agent = None
        self.command_validator = CommandValidator(config['security'])
        self.audit_logger = AuditLogger(config['security']['audit'])
        self.system_executor = SystemExecutor(config['security'])
        
        # Conversation history
        self.conversation_history = []
        
    async def initialize(self):
        """Initialize the agent and its components."""
        try:
            # Initialize LLM
            await self._initialize_llm()
            
            # Initialize AutoGen agent
            await self._initialize_autogen()
            
            # Initialize security components
            self.command_validator.initialize()
            self.audit_logger.initialize()
            
            logger.info("SysAdminAgent initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize SysAdminAgent: {e}")
            raise
    
    async def _initialize_llm(self):
        """Initialize the LLM backend."""
        model_path = self.model_config['path']
        
        if not Path(model_path).exists():
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        logger.info(f"Loading LLM model: {model_path}")
        
        self.llm = Llama(
            model_path=model_path,
            n_ctx=self.model_config['context_length'],
            n_threads=4,  # Optimize for Pi 5
            verbose=False
        )
        
        logger.info("LLM model loaded successfully")
    
    async def _initialize_autogen(self):
        """Initialize the AutoGen agent."""
        # Configure AutoGen
        autogen_config = {
            "config_list": [{
                "model": "qwen2-1.5b",
                "api_key": "dummy",  # Not used for local models
                "api_base": "http://localhost:8082/v1"  # llama.cpp server
            }],
            "temperature": self.model_config['temperature'],
            "max_tokens": self.model_config['max_tokens'],
        }
        
        # Create system message for system administrator
        system_message = self._create_system_message()
        
        # Initialize AutoGen agent
        self.autogen_agent = autogen.AssistantAgent(
            name="SysAdminAgent",
            system_message=system_message,
            llm_config=autogen_config,
            human_input_mode="NEVER",
            max_consecutive_auto_reply=5
        )
        
        logger.info("AutoGen agent initialized")
    
    def _create_system_message(self) -> str:
        """Create the system message for the agent."""
        return """You are an AI System Administrator Agent for a Raspberry Pi server. 
Your role is to help with Linux system administration and DevOps tasks.

CAPABILITIES:
- System monitoring (disk usage, memory, processes)
- Service management (start, stop, restart services)
- Process control and monitoring
- Basic troubleshooting and diagnostics
- Log analysis and system health checks

SAFETY GUIDELINES:
- Always confirm destructive operations
- Explain what commands you're running and why
- Provide clear, conversational responses
- Ask for clarification when needed
- Never run commands that could damage the system

RESPONSE FORMAT:
- Be conversational and helpful
- Explain your actions clearly
- Include the actual commands you're running
- Provide context about what each command does

Remember: You are running on a Raspberry Pi 5 with limited resources. Be efficient and considerate of system resources."""
    
    async def process_request(self, user_input: str) -> str:
        """Process a user request and return a response."""
        try:
            # Log the incoming request
            self.audit_logger.log_request(user_input)
            
            # Add to conversation history
            self.conversation_history.append({"role": "user", "content": user_input})
            
            # Generate response using LLM
            response = await self._generate_response(user_input)
            
            # Extract and validate commands
            commands = self._extract_commands(response)
            validated_commands = []
            
            for command in commands:
                if self.command_validator.is_allowed(command):
                    validated_commands.append(command)
                else:
                    logger.warning(f"Blocked command: {command}")
                    response += f"\n\n⚠️ Command blocked for security: {command}"
            
            # Execute validated commands
            if validated_commands:
                execution_results = await self._execute_commands(validated_commands)
                response += f"\n\n📋 Execution Results:\n{execution_results}"
            
            # Add to conversation history
            self.conversation_history.append({"role": "assistant", "content": response})
            
            # Log the response
            self.audit_logger.log_response(response)
            
            return response
            
        except Exception as e:
            error_msg = f"Error processing request: {e}"
            logger.error(error_msg, exc_info=True)
            self.audit_logger.log_error(error_msg)
            return f"❌ {error_msg}"
    
    async def _generate_response(self, user_input: str) -> str:
        """Generate a response using the LLM."""
        # Create prompt with conversation history
        prompt = self._build_prompt(user_input)
        
        # Generate response
        response = self.llm(
            prompt,
            max_tokens=self.model_config['max_tokens'],
            temperature=self.model_config['temperature'],
            top_p=self.model_config['top_p'],
            stop=["Human:", "User:", "\n\nHuman:", "\n\nUser:"]
        )
        
        return response['choices'][0]['text'].strip()
    
    def _build_prompt(self, user_input: str) -> str:
        """Build the prompt with conversation history."""
        prompt = "You are an AI System Administrator Agent. Help with Linux system administration tasks.\n\n"
        
        # Add recent conversation history (last 5 exchanges)
        recent_history = self.conversation_history[-10:]  # Last 10 messages
        for msg in recent_history:
            role = "Human" if msg["role"] == "user" else "Assistant"
            prompt += f"{role}: {msg['content']}\n\n"
        
        prompt += f"Human: {user_input}\n\nAssistant:"
        return prompt
    
    def _extract_commands(self, response: str) -> List[str]:
        """Extract shell commands from the response."""
        # Look for commands in code blocks or after "Command:" markers
        command_patterns = [
            r'```bash\s*\n(.*?)\n```',
            r'```\s*\n(.*?)\n```',
            r'Command:\s*(.*?)(?:\n|$)',
            r'Run:\s*(.*?)(?:\n|$)',
            r'Execute:\s*(.*?)(?:\n|$)',
        ]
        
        commands = []
        for pattern in command_patterns:
            matches = re.findall(pattern, response, re.MULTILINE | re.DOTALL)
            for match in matches:
                # Clean up the command
                command = match.strip()
                if command and not command.startswith('#'):
                    commands.append(command)
        
        return commands
    
    async def _execute_commands(self, commands: List[str]) -> str:
        """Execute validated commands and return results."""
        results = []
        
        for command in commands:
            try:
                logger.info(f"Executing command: {command}")
                result = await self.system_executor.execute(command)
                results.append(f"✅ {command}\n{result}")
                
            except Exception as e:
                error_msg = f"❌ {command}\nError: {e}"
                results.append(error_msg)
                logger.error(f"Command execution failed: {command} - {e}")
        
        return "\n\n".join(results)
    
    def get_status(self) -> Dict[str, Any]:
        """Get the current status of the agent."""
        return {
            "name": self.agent_config['name'],
            "version": self.agent_config['version'],
            "model_loaded": self.llm is not None,
            "autogen_initialized": self.autogen_agent is not None,
            "conversation_length": len(self.conversation_history),
            "security_enabled": self.command_validator.is_initialized(),
            "audit_logging": self.audit_logger.is_enabled()
        }
