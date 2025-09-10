#!/usr/bin/env python3
"""
AI System Administrator Agent - Main Entry Point
"""

import asyncio
import logging
import sys
from pathlib import Path

from src.agent.sysadmin_agent import SysAdminAgent
from src.interfaces.cli import CLIInterface
from src.interfaces.web import WebInterface
from src.utils.config import load_config
from src.utils.logger import setup_logging

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

logger = logging.getLogger(__name__)


async def main():
    """Main entry point for the AI System Administrator Agent."""
    try:
        # Setup logging
        setup_logging()
        logger.info("Starting AI System Administrator Agent")
        
        # Load configuration
        config = load_config()
        logger.info(f"Configuration loaded: {config['agent']['name']}")
        
        # Initialize the system administrator agent
        agent = SysAdminAgent(config)
        await agent.initialize()
        logger.info("System Administrator Agent initialized")
        
        # Start interfaces based on configuration
        interfaces = []
        
        # CLI Interface
        if config.get('interfaces', {}).get('cli', {}).get('enabled', True):
            cli = CLIInterface(agent, config)
            interfaces.append(cli)
            logger.info("CLI interface enabled")
        
        # Web Interface
        if config.get('interfaces', {}).get('web', {}).get('enabled', True):
            web = WebInterface(agent, config)
            await web.start()
            interfaces.append(web)
            logger.info("Web interface enabled")
        
        # Run interfaces
        if interfaces:
            logger.info(f"Starting {len(interfaces)} interface(s)")
            await asyncio.gather(*[interface.run() for interface in interfaces])
        else:
            logger.warning("No interfaces enabled")
            
    except KeyboardInterrupt:
        logger.info("Received interrupt signal, shutting down...")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
    finally:
        logger.info("AI System Administrator Agent stopped")


if __name__ == "__main__":
    asyncio.run(main())
