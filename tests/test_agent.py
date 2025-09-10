"""
Test suite for the AI System Administrator Agent
"""

import pytest
import asyncio
from unittest.mock import Mock, patch
from pathlib import Path

from src.agent.sysadmin_agent import SysAdminAgent
from src.security.command_validator import CommandValidator
from src.utils.system_executor import SystemExecutor


class TestSysAdminAgent:
    """Test cases for the SysAdminAgent class."""
    
    @pytest.fixture
    def mock_config(self):
        """Mock configuration for testing."""
        return {
            'agent': {
                'name': 'TestAgent',
                'version': '1.0.0',
                'model': {
                    'path': '/tmp/test_model.gguf',
                    'backend': 'llama.cpp',
                    'context_length': 512,
                    'temperature': 0.7,
                    'max_tokens': 100
                }
            },
            'security': {
                'commands': {
                    'allowed': ['df', 'ps', 'uptime'],
                    'forbidden': ['rm -rf /', 'sudo su']
                },
                'filesystem': {
                    'allowed_paths': ['/tmp', '/home'],
                    'forbidden_paths': ['/root', '/etc/shadow']
                },
                'audit': {
                    'enabled': True,
                    'log_file': '/tmp/test_audit.log'
                }
            }
        }
    
    @pytest.fixture
    def agent(self, mock_config):
        """Create a test agent instance."""
        return SysAdminAgent(mock_config)
    
    @pytest.mark.asyncio
    async def test_agent_initialization(self, agent, mock_config):
        """Test agent initialization."""
        # Mock the LLM initialization
        with patch('src.agent.sysadmin_agent.Llama') as mock_llama:
            mock_llama.return_value = Mock()
            
            await agent.initialize()
            
            assert agent.config == mock_config
            assert agent.llm is not None
            assert agent.autogen_agent is not None
    
    def test_system_message_creation(self, agent):
        """Test system message creation."""
        system_message = agent._create_system_message()
        
        assert "AI System Administrator Agent" in system_message
        assert "Linux system administration" in system_message
        assert "Raspberry Pi" in system_message
    
    def test_command_extraction(self, agent):
        """Test command extraction from responses."""
        response = """
        I'll help you check the disk usage.
        
        ```bash
        df -h
        ```
        
        This command will show the disk usage.
        """
        
        commands = agent._extract_commands(response)
        assert "df -h" in commands
    
    def test_prompt_building(self, agent):
        """Test prompt building with conversation history."""
        user_input = "Check disk usage"
        
        # Add some conversation history
        agent.conversation_history = [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi! How can I help?"}
        ]
        
        prompt = agent._build_prompt(user_input)
        
        assert "Hello" in prompt
        assert "Hi! How can I help?" in prompt
        assert user_input in prompt


class TestCommandValidator:
    """Test cases for the CommandValidator class."""
    
    @pytest.fixture
    def security_config(self):
        """Mock security configuration."""
        return {
            'commands': {
                'allowed': ['df', 'ps', 'uptime', 'systemctl status'],
                'forbidden': ['rm -rf /', 'sudo su', 'passwd']
            },
            'filesystem': {
                'allowed_paths': ['/tmp', '/home'],
                'forbidden_paths': ['/root', '/etc/shadow']
            }
        }
    
    @pytest.fixture
    def validator(self, security_config):
        """Create a test validator instance."""
        validator = CommandValidator(security_config)
        validator.initialize()
        return validator
    
    def test_allowed_commands(self, validator):
        """Test that allowed commands pass validation."""
        allowed_commands = ['df -h', 'ps aux', 'uptime', 'systemctl status nginx']
        
        for cmd in allowed_commands:
            assert validator.is_allowed(cmd), f"Command should be allowed: {cmd}"
    
    def test_forbidden_commands(self, validator):
        """Test that forbidden commands are blocked."""
        forbidden_commands = ['rm -rf /', 'sudo su', 'passwd root']
        
        for cmd in forbidden_commands:
            assert not validator.is_allowed(cmd), f"Command should be blocked: {cmd}"
    
    def test_command_cleaning(self, validator):
        """Test command cleaning and normalization."""
        dirty_command = "  df -h  # comment  "
        clean_command = validator._clean_command(dirty_command)
        
        assert clean_command == "df -h"
    
    def test_dangerous_patterns(self, validator):
        """Test detection of dangerous command patterns."""
        dangerous_commands = [
            'rm -rf /',
            'dd if=/dev/zero',
            'mkfs.ext4 /dev/sda',
            'chmod 777 /etc/passwd'
        ]
        
        for cmd in dangerous_commands:
            assert validator._is_forbidden(cmd), f"Dangerous pattern not detected: {cmd}"


class TestSystemExecutor:
    """Test cases for the SystemExecutor class."""
    
    @pytest.fixture
    def security_config(self):
        """Mock security configuration."""
        return {
            'limits': {
                'max_execution_time_seconds': 30,
                'max_memory_mb': 1024,
                'max_cpu_percent': 50
            }
        }
    
    @pytest.fixture
    def executor(self, security_config):
        """Create a test executor instance."""
        return SystemExecutor(security_config)
    
    @pytest.mark.asyncio
    async def test_safe_command_execution(self, executor):
        """Test execution of safe commands."""
        safe_commands = ['uptime', 'whoami', 'date']
        
        for cmd in safe_commands:
            result = await executor.execute(cmd)
            assert isinstance(result, str)
            assert len(result) > 0
    
    @pytest.mark.asyncio
    async def test_command_timeout(self, executor):
        """Test command timeout handling."""
        # This test might be flaky, so we'll mock it
        with patch('asyncio.create_subprocess_exec') as mock_subprocess:
            mock_process = Mock()
            mock_process.communicate.return_value = (b"output", b"error")
            mock_subprocess.return_value = mock_process
            
            # Mock timeout
            with patch('asyncio.wait_for') as mock_wait:
                mock_wait.side_effect = asyncio.TimeoutError()
                
                with pytest.raises(TimeoutError):
                    await executor.execute('sleep 10')
    
    def test_command_safety_check(self, executor):
        """Test command safety checking."""
        safe_commands = ['df -h', 'ps aux', 'uptime']
        unsafe_commands = ['rm -rf /', 'sudo su', 'passwd root']
        
        for cmd in safe_commands:
            is_safe, reason = executor.check_command_safety(cmd)
            assert is_safe, f"Command should be safe: {cmd}"
        
        for cmd in unsafe_commands:
            is_safe, reason = executor.check_command_safety(cmd)
            assert not is_safe, f"Command should be unsafe: {cmd}"
    
    @pytest.mark.asyncio
    async def test_system_info(self, executor):
        """Test system information gathering."""
        info = await executor.get_system_info()
        
        assert isinstance(info, dict)
        # At least one of these should be available
        assert any(key in info for key in ['uptime', 'memory', 'disk', 'load'])


if __name__ == "__main__":
    pytest.main([__file__])
