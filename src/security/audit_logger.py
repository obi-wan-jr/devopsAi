"""
Audit Logger - Security component for logging all agent activities
"""

import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, Any

logger = logging.getLogger(__name__)


class AuditLogger:
    """Logs all agent activities for security auditing."""
    
    def __init__(self, audit_config: dict):
        """Initialize the audit logger."""
        self.config = audit_config
        self.enabled = audit_config.get('enabled', True)
        self.log_file = Path(audit_config.get('log_file', '/tmp/audit.log'))
        self.log_level = audit_config.get('log_level', 'INFO')
        self.log_commands = audit_config.get('log_commands', True)
        self.log_responses = audit_config.get('log_responses', True)
        self.log_errors = audit_config.get('log_errors', True)
        self.retention_days = audit_config.get('retention_days', 30)
        
        self.initialized = False
    
    def initialize(self):
        """Initialize the audit logger."""
        if not self.enabled:
            logger.info("Audit logging disabled")
            return
        
        try:
            # Create log directory if it doesn't exist
            self.log_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Set up file handler
            self._setup_file_handler()
            
            self.initialized = True
            logger.info(f"AuditLogger initialized, logging to: {self.log_file}")
            
        except Exception as e:
            logger.error(f"Failed to initialize AuditLogger: {e}")
            raise
    
    def _setup_file_handler(self):
        """Set up the file handler for audit logging."""
        # Create a separate logger for audit logs
        self.audit_logger = logging.getLogger('audit')
        self.audit_logger.setLevel(getattr(logging, self.log_level))
        
        # Remove existing handlers
        for handler in self.audit_logger.handlers[:]:
            self.audit_logger.removeHandler(handler)
        
        # Create file handler
        file_handler = logging.FileHandler(self.log_file)
        file_handler.setLevel(getattr(logging, self.log_level))
        
        # Create formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        
        # Add handler to logger
        self.audit_logger.addHandler(file_handler)
    
    def log_request(self, request: str, user_id: str = "system"):
        """Log an incoming request."""
        if not self.enabled or not self.initialized:
            return
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": "request",
                "user_id": user_id,
                "request": request,
                "request_length": len(request)
            }
            
            self.audit_logger.info(f"REQUEST: {json.dumps(log_entry)}")
            
        except Exception as e:
            logger.error(f"Failed to log request: {e}")
    
    def log_response(self, response: str, user_id: str = "system"):
        """Log an outgoing response."""
        if not self.enabled or not self.initialized or not self.log_responses:
            return
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": "response",
                "user_id": user_id,
                "response": response,
                "response_length": len(response)
            }
            
            self.audit_logger.info(f"RESPONSE: {json.dumps(log_entry)}")
            
        except Exception as e:
            logger.error(f"Failed to log response: {e}")
    
    def log_command(self, command: str, result: str, success: bool, user_id: str = "system"):
        """Log a command execution."""
        if not self.enabled or not self.initialized or not self.log_commands:
            return
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": "command",
                "user_id": user_id,
                "command": command,
                "success": success,
                "result_length": len(result) if result else 0
            }
            
            self.audit_logger.info(f"COMMAND: {json.dumps(log_entry)}")
            
        except Exception as e:
            logger.error(f"Failed to log command: {e}")
    
    def log_error(self, error: str, context: Dict[str, Any] = None, user_id: str = "system"):
        """Log an error."""
        if not self.enabled or not self.initialized or not self.log_errors:
            return
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": "error",
                "user_id": user_id,
                "error": error,
                "context": context or {}
            }
            
            self.audit_logger.error(f"ERROR: {json.dumps(log_entry)}")
            
        except Exception as e:
            logger.error(f"Failed to log error: {e}")
    
    def log_security_event(self, event_type: str, details: Dict[str, Any], user_id: str = "system"):
        """Log a security-related event."""
        if not self.enabled or not self.initialized:
            return
        
        try:
            log_entry = {
                "timestamp": datetime.utcnow().isoformat(),
                "event_type": "security",
                "security_event": event_type,
                "user_id": user_id,
                "details": details
            }
            
            self.audit_logger.warning(f"SECURITY: {json.dumps(log_entry)}")
            
        except Exception as e:
            logger.error(f"Failed to log security event: {e}")
    
    def is_enabled(self) -> bool:
        """Check if audit logging is enabled."""
        return self.enabled and self.initialized
    
    def cleanup_old_logs(self):
        """Clean up old log entries based on retention policy."""
        if not self.enabled or not self.initialized:
            return
        
        try:
            # This is a simple implementation
            # In production, you might want to use logrotate or similar
            if self.log_file.exists():
                # Check file age and size
                file_age_days = (datetime.now() - datetime.fromtimestamp(
                    self.log_file.stat().st_mtime
                )).days
                
                if file_age_days > self.retention_days:
                    # Archive or delete old logs
                    archive_file = self.log_file.with_suffix(
                        f'.{datetime.now().strftime("%Y%m%d")}.log'
                    )
                    self.log_file.rename(archive_file)
                    logger.info(f"Archived old audit log: {archive_file}")
        
        except Exception as e:
            logger.error(f"Failed to cleanup old logs: {e}")
