"""
CLI Interface - Command-line interface for the AI System Administrator Agent
"""

import asyncio
import logging
from typing import Dict, Any

import click
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt
from rich.text import Text

from src.agent.sysadmin_agent import SysAdminAgent

logger = logging.getLogger(__name__)
console = Console()


class CLIInterface:
    """Command-line interface for the AI System Administrator Agent."""
    
    def __init__(self, agent: SysAdminAgent, config: Dict[str, Any]):
        """Initialize the CLI interface."""
        self.agent = agent
        self.config = config
        self.running = False
    
    async def run(self):
        """Run the CLI interface."""
        self.running = True
        
        # Display welcome message
        self._display_welcome()
        
        try:
            while self.running:
                try:
                    # Get user input
                    user_input = Prompt.ask(
                        "\n[bold blue]SysAdmin Agent[/bold blue]",
                        default=""
                    ).strip()
                    
                    if not user_input:
                        continue
                    
                    # Handle special commands
                    if user_input.lower() in ['exit', 'quit', 'bye']:
                        self._display_goodbye()
                        break
                    
                    if user_input.lower() in ['help', '?']:
                        self._display_help()
                        continue
                    
                    if user_input.lower() == 'status':
                        self._display_status()
                        continue
                    
                    if user_input.lower() == 'clear':
                        console.clear()
                        continue
                    
                    # Process the request
                    await self._process_request(user_input)
                    
                except KeyboardInterrupt:
                    console.print("\n[yellow]Use 'exit' to quit or Ctrl+C again to force quit[/yellow]")
                    try:
                        await asyncio.sleep(1)
                    except KeyboardInterrupt:
                        break
                        
                except Exception as e:
                    console.print(f"[red]Error: {e}[/red]")
                    logger.error(f"CLI error: {e}", exc_info=True)
        
        except Exception as e:
            logger.error(f"CLI fatal error: {e}", exc_info=True)
        finally:
            self.running = False
    
    def _display_welcome(self):
        """Display welcome message."""
        welcome_text = Text()
        welcome_text.append("🤖 AI System Administrator Agent\n", style="bold blue")
        welcome_text.append("Ready to help with Linux system administration tasks!\n\n", style="green")
        welcome_text.append("Type 'help' for available commands or 'exit' to quit.", style="dim")
        
        panel = Panel(
            welcome_text,
            title="Welcome",
            border_style="blue",
            padding=(1, 2)
        )
        console.print(panel)
    
    def _display_goodbye(self):
        """Display goodbye message."""
        goodbye_text = Text()
        goodbye_text.append("👋 Goodbye! Thanks for using the AI System Administrator Agent.", style="green")
        
        panel = Panel(
            goodbye_text,
            title="Farewell",
            border_style="green",
            padding=(1, 2)
        )
        console.print(panel)
    
    def _display_help(self):
        """Display help information."""
        help_text = Text()
        help_text.append("Available Commands:\n", style="bold")
        help_text.append("• help, ? - Show this help message\n", style="cyan")
        help_text.append("• status - Show agent status\n", style="cyan")
        help_text.append("• clear - Clear the screen\n", style="cyan")
        help_text.append("• exit, quit, bye - Exit the application\n\n", style="cyan")
        
        help_text.append("Example System Admin Requests:\n", style="bold")
        help_text.append("• 'Check disk usage'\n", style="yellow")
        help_text.append("• 'Show running processes'\n", style="yellow")
        help_text.append("• 'Restart nginx service'\n", style="yellow")
        help_text.append("• 'Check system memory usage'\n", style="yellow")
        help_text.append("• 'Show system uptime'\n", style="yellow")
        help_text.append("• 'List all services'\n", style="yellow")
        
        panel = Panel(
            help_text,
            title="Help",
            border_style="cyan",
            padding=(1, 2)
        )
        console.print(panel)
    
    def _display_status(self):
        """Display agent status."""
        status = self.agent.get_status()
        
        status_text = Text()
        status_text.append(f"Agent: {status['name']} v{status['version']}\n", style="bold")
        status_text.append(f"Model Loaded: {'✅' if status['model_loaded'] else '❌'}\n", style="green" if status['model_loaded'] else "red")
        status_text.append(f"AutoGen Initialized: {'✅' if status['autogen_initialized'] else '❌'}\n", style="green" if status['autogen_initialized'] else "red")
        status_text.append(f"Security Enabled: {'✅' if status['security_enabled'] else '❌'}\n", style="green" if status['security_enabled'] else "red")
        status_text.append(f"Audit Logging: {'✅' if status['audit_logging'] else '❌'}\n", style="green" if status['audit_logging'] else "red")
        status_text.append(f"Conversation Length: {status['conversation_length']}", style="dim")
        
        panel = Panel(
            status_text,
            title="Agent Status",
            border_style="green",
            padding=(1, 2)
        )
        console.print(panel)
    
    async def _process_request(self, user_input: str):
        """Process a user request."""
        try:
            # Show processing indicator
            with console.status("[bold green]Processing request..."):
                response = await self.agent.process_request(user_input)
            
            # Display response
            self._display_response(response)
            
        except Exception as e:
            error_text = Text()
            error_text.append(f"❌ Error processing request: {e}", style="red")
            
            panel = Panel(
                error_text,
                title="Error",
                border_style="red",
                padding=(1, 2)
            )
            console.print(panel)
    
    def _display_response(self, response: str):
        """Display the agent's response."""
        response_text = Text()
        response_text.append(response, style="white")
        
        panel = Panel(
            response_text,
            title="Agent Response",
            border_style="green",
            padding=(1, 2)
        )
        console.print(panel)


@click.command()
@click.option('--config', '-c', help='Configuration file path')
@click.option('--verbose', '-v', is_flag=True, help='Enable verbose logging')
def cli_main(config, verbose):
    """AI System Administrator Agent CLI."""
    # This would be used if running the CLI directly
    pass


if __name__ == "__main__":
    cli_main()
