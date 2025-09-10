"""
Configuration Management - Load and validate configuration files
"""

import logging
import yaml
from pathlib import Path
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)


def load_config(config_dir: Optional[Path] = None) -> Dict[str, Any]:
    """Load configuration from YAML files."""
    if config_dir is None:
        config_dir = Path(__file__).parent.parent.parent / "config"
    
    config = {}
    
    try:
        # Load agent configuration
        agent_config_file = config_dir / "agent.yaml"
        if agent_config_file.exists():
            with open(agent_config_file, 'r') as f:
                config.update(yaml.safe_load(f))
        else:
            logger.warning(f"Agent config file not found: {agent_config_file}")
        
        # Load security configuration
        security_config_file = config_dir / "security.yaml"
        if security_config_file.exists():
            with open(security_config_file, 'r') as f:
                config['security'] = yaml.safe_load(f)
        else:
            logger.warning(f"Security config file not found: {security_config_file}")
        
        # Load interface configuration
        interface_config_file = config_dir / "interfaces.yaml"
        if interface_config_file.exists():
            with open(interface_config_file, 'r') as f:
                config['interfaces'] = yaml.safe_load(f)
        else:
            # Default interface configuration
            config['interfaces'] = {
                'cli': {'enabled': True},
                'web': {'enabled': True, 'host': '0.0.0.0', 'port': 8080},
                'api': {'enabled': True, 'port': 8081}
            }
        
        logger.info("Configuration loaded successfully")
        return config
        
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        raise


def validate_config(config: Dict[str, Any]) -> bool:
    """Validate the loaded configuration."""
    try:
        # Check required sections
        required_sections = ['agent', 'security']
        for section in required_sections:
            if section not in config:
                logger.error(f"Missing required configuration section: {section}")
                return False
        
        # Validate agent configuration
        agent_config = config['agent']
        required_agent_fields = ['name', 'model']
        for field in required_agent_fields:
            if field not in agent_config:
                logger.error(f"Missing required agent field: {field}")
                return False
        
        # Validate model configuration
        model_config = agent_config['model']
        required_model_fields = ['path', 'backend']
        for field in required_model_fields:
            if field not in model_config:
                logger.error(f"Missing required model field: {field}")
                return False
        
        # Check if model file exists
        model_path = Path(model_config['path'])
        if not model_path.exists():
            logger.warning(f"Model file not found: {model_path}")
        
        # Validate security configuration
        security_config = config['security']
        required_security_fields = ['commands', 'filesystem']
        for field in required_security_fields:
            if field not in security_config:
                logger.error(f"Missing required security field: {field}")
                return False
        
        logger.info("Configuration validation passed")
        return True
        
    except Exception as e:
        logger.error(f"Configuration validation failed: {e}")
        return False


def get_config_value(config: Dict[str, Any], key_path: str, default: Any = None) -> Any:
    """Get a configuration value using dot notation."""
    try:
        keys = key_path.split('.')
        value = config
        
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        
        return value
        
    except Exception as e:
        logger.error(f"Failed to get config value '{key_path}': {e}")
        return default


def update_config_value(config: Dict[str, Any], key_path: str, value: Any) -> bool:
    """Update a configuration value using dot notation."""
    try:
        keys = key_path.split('.')
        current = config
        
        # Navigate to the parent of the target key
        for key in keys[:-1]:
            if key not in current:
                current[key] = {}
            current = current[key]
        
        # Set the value
        current[keys[-1]] = value
        return True
        
    except Exception as e:
        logger.error(f"Failed to update config value '{key_path}': {e}")
        return False
