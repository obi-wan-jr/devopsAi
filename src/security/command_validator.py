"""
Command Validator - Security component for validating system commands
"""

import logging
import re
from typing import List, Set
from pathlib import Path

logger = logging.getLogger(__name__)


class CommandValidator:
    """Validates system commands against security policies."""
    
    def __init__(self, security_config: dict):
        """Initialize the command validator."""
        self.config = security_config
        self.allowed_commands: Set[str] = set()
        self.forbidden_commands: Set[str] = set()
        self.allowed_paths: List[Path] = []
        self.forbidden_paths: List[Path] = []
        self.initialized = False
    
    def initialize(self):
        """Initialize the validator with security policies."""
        try:
            # Load allowed commands
            self.allowed_commands = set(
                self.config['commands']['allowed']
            )
            
            # Load forbidden commands
            self.forbidden_commands = set(
                self.config['commands']['forbidden']
            )
            
            # Load allowed paths
            self.allowed_paths = [
                Path(p) for p in self.config['filesystem']['allowed_paths']
            ]
            
            # Load forbidden paths
            self.forbidden_paths = [
                Path(p) for p in self.config['filesystem']['forbidden_paths']
            ]
            
            self.initialized = True
            logger.info(f"CommandValidator initialized with {len(self.allowed_commands)} allowed commands")
            
        except Exception as e:
            logger.error(f"Failed to initialize CommandValidator: {e}")
            raise
    
    def is_allowed(self, command: str) -> bool:
        """Check if a command is allowed by security policies."""
        if not self.initialized:
            logger.error("CommandValidator not initialized")
            return False
        
        try:
            # Clean and normalize the command
            clean_command = self._clean_command(command)
            
            # Check against forbidden commands first
            if self._is_forbidden(clean_command):
                logger.warning(f"Command blocked (forbidden): {clean_command}")
                return False
            
            # Check against allowed commands
            if self._is_explicitly_allowed(clean_command):
                return True
            
            # Check if command accesses forbidden paths
            if self._accesses_forbidden_paths(clean_command):
                logger.warning(f"Command blocked (forbidden path): {clean_command}")
                return False
            
            # Check if command is safe based on patterns
            if self._is_safe_pattern(clean_command):
                return True
            
            # Default: block unknown commands
            logger.warning(f"Command blocked (not in whitelist): {clean_command}")
            return False
            
        except Exception as e:
            logger.error(f"Error validating command '{command}': {e}")
            return False
    
    def _clean_command(self, command: str) -> str:
        """Clean and normalize a command string."""
        # Remove leading/trailing whitespace
        command = command.strip()
        
        # Remove comments
        command = re.sub(r'#.*$', '', command, flags=re.MULTILINE)
        
        # Remove multiple spaces
        command = re.sub(r'\s+', ' ', command)
        
        return command
    
    def _is_forbidden(self, command: str) -> bool:
        """Check if command matches any forbidden patterns."""
        command_lower = command.lower()
        
        for forbidden in self.forbidden_commands:
            if forbidden.lower() in command_lower:
                return True
        
        # Additional pattern-based checks
        dangerous_patterns = [
            r'rm\s+-rf\s+/',  # rm -rf /
            r'dd\s+if=/dev/zero',  # dd if=/dev/zero
            r'mkfs\s+',  # mkfs commands
            r'fdisk\s+',  # fdisk commands
            r'chmod\s+777',  # chmod 777
            r'chown\s+root',  # chown root
            r'passwd\s+',  # passwd commands
            r'su\s+',  # su commands
            r'sudo\s+su',  # sudo su
        ]
        
        for pattern in dangerous_patterns:
            if re.search(pattern, command_lower):
                return True
        
        return False
    
    def _is_explicitly_allowed(self, command: str) -> bool:
        """Check if command is explicitly in the allowed list."""
        # Extract the base command (first word)
        base_command = command.split()[0] if command.split() else ""
        
        # Check exact matches
        if command in self.allowed_commands:
            return True
        
        # Check base command matches
        if base_command in self.allowed_commands:
            return True
        
        # Check pattern matches for systemctl
        if base_command == "systemctl":
            systemctl_patterns = [
                "systemctl status",
                "systemctl start",
                "systemctl stop", 
                "systemctl restart",
                "systemctl enable",
                "systemctl disable"
            ]
            for pattern in systemctl_patterns:
                if command.startswith(pattern):
                    return True
        
        return False
    
    def _accesses_forbidden_paths(self, command: str) -> bool:
        """Check if command accesses forbidden file system paths."""
        command_lower = command.lower()
        
        for forbidden_path in self.forbidden_paths:
            if str(forbidden_path).lower() in command_lower:
                return True
        
        return False
    
    def _is_safe_pattern(self, command: str) -> bool:
        """Check if command matches safe patterns."""
        safe_patterns = [
            r'^df\s*$',  # df
            r'^du\s+',  # du with path
            r'^free\s*$',  # free
            r'^top\s*$',  # top
            r'^ps\s+',  # ps with options
            r'^ls\s+',  # ls with options
            r'^cat\s+',  # cat with file
            r'^tail\s+',  # tail with file
            r'^head\s+',  # head with file
            r'^grep\s+',  # grep with pattern
            r'^find\s+',  # find with path
            r'^ping\s+',  # ping with host
            r'^uptime\s*$',  # uptime
            r'^who\s*$',  # who
            r'^w\s*$',  # w
            r'^uname\s*$',  # uname
            r'^hostname\s*$',  # hostname
            r'^date\s*$',  # date
        ]
        
        for pattern in safe_patterns:
            if re.match(pattern, command):
                return True
        
        return False
    
    def is_initialized(self) -> bool:
        """Check if the validator is initialized."""
        return self.initialized
    
    def get_allowed_commands(self) -> List[str]:
        """Get list of allowed commands."""
        return list(self.allowed_commands)
    
    def get_forbidden_commands(self) -> List[str]:
        """Get list of forbidden commands."""
        return list(self.forbidden_commands)
