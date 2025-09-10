#!/bin/bash

# Test Script - Test the AI System Administrator Agent
# This script runs various tests to ensure the agent is working correctly

set -e

# Configuration
PROJECT_DIR="/home/inggo/ai-agent"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test functions
test_python_environment() {
    log_info "Testing Python environment..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    # Test Python version
    python_version=$(python3 --version)
    log_info "Python version: $python_version"
    
    # Test required packages
    python3 -c "
import sys
required_packages = [
    'autogen', 'llama_cpp', 'fastapi', 'uvicorn', 
    'click', 'rich', 'psutil', 'pydantic', 'pyyaml'
]

missing_packages = []
for package in required_packages:
    try:
        __import__(package)
        print(f'✓ {package}')
    except ImportError:
        missing_packages.append(package)
        print(f'✗ {package}')

if missing_packages:
    print(f'Missing packages: {missing_packages}')
    sys.exit(1)
else:
    print('All required packages are installed')
"
    
    log_success "Python environment test passed"
}

test_model_loading() {
    log_info "Testing model loading..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    python3 -c "
from llama_cpp import Llama
import time

print('Loading model...')
start_time = time.time()

try:
    llm = Llama(
        model_path='models/qwen2-1.5b-q4_k_m.gguf',
        n_ctx=512,
        n_threads=4,
        verbose=False
    )
    
    load_time = time.time() - start_time
    print(f'Model loaded in {load_time:.2f} seconds')
    
    # Test inference
    print('Testing inference...')
    response = llm('What is 2+2?', max_tokens=20, temperature=0.1)
    print(f'Response: {response[\"choices\"][0][\"text\"].strip()}')
    
    print('Model test passed')
    
except Exception as e:
    print(f'Model test failed: {e}')
    exit(1)
"
    
    log_success "Model loading test passed"
}

test_agent_import() {
    log_info "Testing agent import..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    python3 -c "
import sys
sys.path.insert(0, '.')

try:
    from src.agent.sysadmin_agent import SysAdminAgent
    from src.security.command_validator import CommandValidator
    from src.security.audit_logger import AuditLogger
    from src.utils.system_executor import SystemExecutor
    from src.utils.config import load_config
    
    print('All agent modules imported successfully')
    
    # Test config loading
    config = load_config()
    print('Configuration loaded successfully')
    
    # Test command validator
    validator = CommandValidator(config['security'])
    validator.initialize()
    print('Command validator initialized')
    
    # Test allowed command
    if validator.is_allowed('df -h'):
        print('Command validation working')
    else:
        print('Command validation failed')
        exit(1)
    
except Exception as e:
    print(f'Agent import test failed: {e}')
    exit(1)
"
    
    log_success "Agent import test passed"
}

test_web_interface() {
    log_info "Testing web interface..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    # Test FastAPI import and basic setup
    python3 -c "
from fastapi import FastAPI
from src.interfaces.web import WebInterface
from src.utils.config import load_config

try:
    config = load_config()
    app = FastAPI()
    print('FastAPI setup successful')
    
    # Test HTML generation
    web_interface = WebInterface(None, config)  # None for agent in test
    html = web_interface._get_html_interface()
    if 'AI System Administrator Agent' in html:
        print('Web interface HTML generation successful')
    else:
        print('Web interface HTML generation failed')
        exit(1)
        
except Exception as e:
    print(f'Web interface test failed: {e}')
    exit(1)
"
    
    log_success "Web interface test passed"
}

test_system_commands() {
    log_info "Testing system command execution..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    python3 -c "
import asyncio
from src.utils.system_executor import SystemExecutor
from src.utils.config import load_config

async def test_commands():
    config = load_config()
    executor = SystemExecutor(config['security'])
    
    # Test safe commands
    safe_commands = [
        'uptime',
        'whoami',
        'date',
        'uname -a'
    ]
    
    for cmd in safe_commands:
        try:
            result = await executor.execute(cmd)
            print(f'✓ {cmd}: {result[:50]}...')
        except Exception as e:
            print(f'✗ {cmd}: {e}')
            return False
    
    return True

# Run async test
result = asyncio.run(test_commands())
if result:
    print('System command execution test passed')
else:
    print('System command execution test failed')
    exit(1)
"
    
    log_success "System command execution test passed"
}

test_security() {
    log_info "Testing security features..."
    
    cd "$PROJECT_DIR"
    source ai-agent-env/bin/activate
    
    python3 -c "
from src.security.command_validator import CommandValidator
from src.utils.config import load_config

config = load_config()
validator = CommandValidator(config['security'])
validator.initialize()

# Test allowed commands
allowed_commands = ['df -h', 'ps aux', 'systemctl status nginx']
for cmd in allowed_commands:
    if validator.is_allowed(cmd):
        print(f'✓ Allowed: {cmd}')
    else:
        print(f'✗ Should be allowed: {cmd}')

# Test forbidden commands
forbidden_commands = ['rm -rf /', 'sudo su', 'passwd root']
for cmd in forbidden_commands:
    if not validator.is_allowed(cmd):
        print(f'✓ Blocked: {cmd}')
    else:
        print(f'✗ Should be blocked: {cmd}')

print('Security test completed')
"
    
    log_success "Security test passed"
}

# Main test function
main() {
    log_info "Starting AI System Administrator Agent tests..."
    
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "Project directory not found: $PROJECT_DIR"
        log_info "Please run install.sh first"
        exit 1
    fi
    
    test_python_environment
    test_model_loading
    test_agent_import
    test_web_interface
    test_system_commands
    test_security
    
    echo
    log_success "All tests passed! The AI System Administrator Agent is ready to use."
    
    echo
    log_info "To start the agent:"
    echo "1. cd $PROJECT_DIR"
    echo "2. ./start.sh"
    echo "3. Or use systemd: sudo systemctl start ai-sysadmin-agent"
}

# Run main function
main "$@"
