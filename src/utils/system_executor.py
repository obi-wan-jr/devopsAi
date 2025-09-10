"""
System Executor - Safe execution of system commands
"""

import asyncio
import logging
import os
import subprocess
import shlex
from typing import Tuple, Optional
from pathlib import Path

logger = logging.getLogger(__name__)


class SystemExecutor:
    """Safely executes system commands with security restrictions."""
    
    def __init__(self, security_config: dict):
        """Initialize the system executor."""
        self.config = security_config
        self.limits = security_config.get('limits', {})
        self.max_execution_time = self.limits.get('max_execution_time_seconds', 300)
        self.max_memory_mb = self.limits.get('max_memory_mb', 2048)
        self.max_cpu_percent = self.limits.get('max_cpu_percent', 80)
    
    async def execute(self, command: str, timeout: Optional[int] = None) -> str:
        """Execute a system command safely."""
        try:
            # Use provided timeout or default
            timeout = timeout or self.max_execution_time
            
            # Parse command
            cmd_parts = shlex.split(command)
            if not cmd_parts:
                raise ValueError("Empty command")
            
            logger.info(f"Executing command: {command}")
            
            # Execute command with timeout
            process = await asyncio.create_subprocess_exec(
                *cmd_parts,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=Path.home(),  # Start in user's home directory
                env=self._get_safe_environment()
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout
                )
                
                # Decode output
                stdout_text = stdout.decode('utf-8', errors='replace')
                stderr_text = stderr.decode('utf-8', errors='replace')
                
                # Check return code
                if process.returncode == 0:
                    result = stdout_text
                    if stderr_text:
                        result += f"\n[STDERR]\n{stderr_text}"
                else:
                    result = f"Command failed with exit code {process.returncode}\n"
                    if stderr_text:
                        result += f"[STDERR]\n{stderr_text}"
                    if stdout_text:
                        result += f"[STDOUT]\n{stdout_text}"
                
                logger.info(f"Command completed: {command} (exit code: {process.returncode})")
                return result
                
            except asyncio.TimeoutError:
                # Kill the process if it times out
                process.kill()
                await process.wait()
                raise TimeoutError(f"Command timed out after {timeout} seconds")
            
        except Exception as e:
            error_msg = f"Failed to execute command '{command}': {e}"
            logger.error(error_msg)
            raise
    
    def _get_safe_environment(self) -> dict:
        """Get a safe environment for command execution."""
        # Start with minimal environment
        safe_env = {
            'PATH': '/usr/local/bin:/usr/bin:/bin',
            'HOME': str(Path.home()),
            'USER': 'inggo',
            'SHELL': '/bin/bash',
            'TERM': 'xterm-256color',
            'LANG': 'en_US.UTF-8',
            'LC_ALL': 'en_US.UTF-8'
        }
        
        # Add safe environment variables
        safe_vars = [
            'TZ', 'TMPDIR', 'XDG_RUNTIME_DIR'
        ]
        
        for var in safe_vars:
            if var in os.environ:
                safe_env[var] = os.environ[var]
        
        return safe_env
    
    async def execute_with_sudo(self, command: str, timeout: Optional[int] = None) -> str:
        """Execute a command with sudo privileges."""
        # This should only be used for specific, validated commands
        sudo_command = f"sudo {command}"
        return await self.execute(sudo_command, timeout)
    
    def check_command_safety(self, command: str) -> Tuple[bool, str]:
        """Check if a command is safe to execute."""
        try:
            # Basic safety checks
            if not command or not command.strip():
                return False, "Empty command"
            
            # Check for dangerous patterns
            dangerous_patterns = [
                'rm -rf /',
                'dd if=/dev/zero',
                'mkfs',
                'fdisk',
                'chmod 777',
                'chown root',
                'passwd',
                'su ',
                'sudo su'
            ]
            
            command_lower = command.lower()
            for pattern in dangerous_patterns:
                if pattern in command_lower:
                    return False, f"Dangerous pattern detected: {pattern}"
            
            # Check for path traversal
            if '../' in command or '..\\' in command:
                return False, "Path traversal detected"
            
            return True, "Command appears safe"
            
        except Exception as e:
            return False, f"Safety check failed: {e}"
    
    async def get_system_info(self) -> dict:
        """Get basic system information."""
        try:
            info = {}
            
            # Get system uptime
            try:
                result = await self.execute('uptime')
                info['uptime'] = result.strip()
            except:
                info['uptime'] = "Unknown"
            
            # Get memory usage
            try:
                result = await self.execute('free -h')
                info['memory'] = result.strip()
            except:
                info['memory'] = "Unknown"
            
            # Get disk usage
            try:
                result = await self.execute('df -h')
                info['disk'] = result.strip()
            except:
                info['disk'] = "Unknown"
            
            # Get load average
            try:
                result = await self.execute('cat /proc/loadavg')
                info['load'] = result.strip()
            except:
                info['load'] = "Unknown"
            
            return info
            
        except Exception as e:
            logger.error(f"Failed to get system info: {e}")
            return {"error": str(e)}
