// Dashboard JavaScript - Combined Chat and Monitor functionality

document.addEventListener('DOMContentLoaded', function() {
    // Initialize both chat and monitor functionality
    initializeChat();
    initializeMonitor();
    initializeNavigation();
});

// Chat Functionality
function initializeChat() {
    const messageInput = document.getElementById('messageInput');
    const sendButton = document.getElementById('sendButton');
    const chatMessages = document.getElementById('chatMessages');
    const modelIndicator = document.getElementById('modelIndicator');
    const connectionStatus = document.getElementById('connectionStatus');
    const quickButtons = document.querySelectorAll('.quick-btn');

    // Model selection
    const modelRadios = document.querySelectorAll('input[name="model"]');
    modelRadios.forEach(radio => {
        radio.addEventListener('change', function() {
            const selectedModel = this.value;
            updateModelIndicator(selectedModel);
        });
    });

    // Send message
    sendButton.addEventListener('click', sendMessage);
    messageInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Quick action buttons
    quickButtons.forEach(button => {
        button.addEventListener('click', function() {
            const action = this.dataset.action;
            const messages = {
                'system-status': 'Show me the current system status and health',
                'docker-status': 'Show me all Docker containers and their status',
                'network-check': 'Check network connectivity and show open ports',
                'security-check': 'Perform a basic security check of my system',
                'performance-analysis': 'Analyze system performance and suggest optimizations'
            };
            
            if (messages[action]) {
                messageInput.value = messages[action];
                sendMessage();
            }
        });
    });

    // Auto-resize textarea
    messageInput.addEventListener('input', function() {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 120) + 'px';
    });

    function updateModelIndicator(model) {
        const indicators = {
            'auto': '🧠 Auto-Select',
            'gemma3': '⚡ Gemma 3 (1B)',
            'deepseek': '🧠 DeepSeek-R1 (1.5B)'
        };
        modelIndicator.textContent = indicators[model] || 'Auto-Select';
    }

    function sendMessage() {
        const message = messageInput.value.trim();
        if (!message) return;

        const selectedModel = document.querySelector('input[name="model"]:checked').value;
        
        // Add user message to chat
        addMessage('user', message);
        messageInput.value = '';
        messageInput.style.height = 'auto';

        // Show loading
        showLoading();

        // Determine API endpoint - use relative URL for same-origin requests
        let endpoint = '/api/chat';
        if (selectedModel !== 'auto') {
            endpoint += `/${selectedModel}`;
        }

        // Send request
        fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: message,
                stream: false
            })
        })
        .then(response => response.json())
        .then(data => {
            hideLoading();
            if (data.response) {
                addMessage('assistant', data.response, data.model_used);
                updateConnectionStatus('connected');
            } else {
                addMessage('system', 'Error: ' + (data.error || 'Unknown error occurred'));
                updateConnectionStatus('error');
            }
        })
        .catch(error => {
            hideLoading();
            addMessage('system', 'Connection error: ' + error.message);
            updateConnectionStatus('error');
        });
    }

    function addMessage(type, content, modelUsed = null) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}-message`;
        
        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        contentDiv.innerHTML = content.replace(/\n/g, '<br>');
        
        const timeDiv = document.createElement('div');
        timeDiv.className = 'message-time';
        timeDiv.textContent = modelUsed ? `${modelUsed} • ${new Date().toLocaleTimeString()}` : new Date().toLocaleTimeString();
        
        messageDiv.appendChild(contentDiv);
        messageDiv.appendChild(timeDiv);
        
        chatMessages.appendChild(messageDiv);
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    function updateConnectionStatus(status) {
        const statusMap = {
            'connected': '🟢 Connected',
            'error': '🔴 Error',
            'connecting': '🟡 Connecting'
        };
        connectionStatus.textContent = statusMap[status] || '🟢 Connected';
    }

    function showLoading() {
        updateConnectionStatus('connecting');
        sendButton.disabled = true;
        sendButton.innerHTML = '<span class="loading-spinner" style="width: 20px; height: 20px; border: 2px solid #f3f3f3; border-top: 2px solid #3498db; border-radius: 50%; animation: spin 1s linear infinite;"></span> Sending...';
    }

    function hideLoading() {
        sendButton.disabled = false;
        sendButton.innerHTML = '<span class="send-icon">📤</span> Send';
    }

    // Check initial connection
    checkConnection();
}

// Monitor Functionality
function initializeMonitor() {
    const logContainer = document.getElementById('logContainer');
    const refreshBtn = document.getElementById('refreshBtn');
    const clearBtn = document.getElementById('clearBtn');
    const exportBtn = document.getElementById('exportBtn');
    const autoRefresh = document.getElementById('autoRefresh');
    const serviceFilter = document.getElementById('serviceFilter');
    const levelFilter = document.getElementById('levelFilter');
    const statusElements = {
        gateway: document.getElementById('gatewayStatus'),
        gemma: document.getElementById('gemmaStatus'),
        deepseek: document.getElementById('deepseekStatus')
    };

    let refreshInterval;
    let logEntries = [];

    // Event listeners
    refreshBtn.addEventListener('click', refreshLogs);
    clearBtn.addEventListener('click', clearLogs);
    exportBtn.addEventListener('click', exportLogs);
    autoRefresh.addEventListener('change', toggleAutoRefresh);
    serviceFilter.addEventListener('change', filterLogs);
    levelFilter.addEventListener('change', filterLogs);

    // Initial load
    refreshLogs();
    checkServiceStatus();

    function refreshLogs() {
        // Simulate fetching logs from services
        // In a real implementation, this would fetch from your logging system
        fetchServiceLogs();
    }

    function fetchServiceLogs() {
        // Check API Gateway logs
        fetch('/api/health')
            .then(response => response.json())
            .then(data => {
                addLogEntry('api-gateway', 'info', `Health check: ${data.status}`);
            })
            .catch(error => {
                addLogEntry('api-gateway', 'error', `Health check failed: ${error.message}`);
            });

        // Check Gemma 3 logs
        fetch('/api/gemma3/models')
            .then(response => response.json())
            .then(data => {
                addLogEntry('ollama-gemma3', 'info', `Model available: ${data.models ? data.models.length : 0} models`);
            })
            .catch(error => {
                addLogEntry('ollama-gemma3', 'error', `Model check failed: ${error.message}`);
            });

        // Check DeepSeek-R1 logs
        fetch('/api/deepseek/models')
            .then(response => response.json())
            .then(data => {
                addLogEntry('ollama-deepseek', 'info', `Model available: ${data.models ? data.models.length : 0} models`);
            })
            .catch(error => {
                addLogEntry('ollama-deepseek', 'error', `Model check failed: ${error.message}`);
            });
    }

    function addLogEntry(service, level, message) {
        const timestamp = new Date().toLocaleString();
        const entry = {
            timestamp,
            service,
            level,
            message,
            id: Date.now() + Math.random()
        };

        logEntries.unshift(entry); // Add to beginning
        if (logEntries.length > 100) {
            logEntries = logEntries.slice(0, 100); // Keep only last 100 entries
        }

        updateLogDisplay();
        updateStats();
    }

    function updateLogDisplay() {
        const serviceFilterValue = document.getElementById('serviceFilter').value;
        const levelFilterValue = document.getElementById('levelFilter').value;
        
        const filteredEntries = logEntries.filter(entry => {
            const serviceMatch = serviceFilterValue === 'all' || entry.service === serviceFilterValue;
            const levelMatch = levelFilterValue === 'all' || entry.level === levelFilterValue;
            return serviceMatch && levelMatch;
        });

        logContainer.innerHTML = '';
        filteredEntries.forEach(entry => {
            const entryDiv = document.createElement('div');
            entryDiv.className = `log-entry ${entry.level} new`;
            entryDiv.innerHTML = `
                <div class="log-timestamp">${entry.timestamp}</div>
                <div class="log-service">${entry.service}</div>
                <div class="log-level">${entry.level}</div>
                <div class="log-message">${entry.message}</div>
            `;
            logContainer.appendChild(entryDiv);
        });
    }

    function updateStats() {
        const totalCommands = logEntries.length;
        const successCount = logEntries.filter(entry => entry.level === 'info').length;
        const successRate = totalCommands > 0 ? Math.round((successCount / totalCommands) * 100) : 0;
        
        document.getElementById('totalCommands').textContent = totalCommands;
        document.getElementById('successRate').textContent = `${successRate}%`;
        document.getElementById('avgResponse').textContent = '~150ms'; // Simulated
    }

    function clearLogs() {
        logEntries = [];
        updateLogDisplay();
        updateStats();
    }

    function exportLogs() {
        const dataStr = JSON.stringify(logEntries, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        const url = URL.createObjectURL(dataBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `ai-agent-logs-${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        URL.revokeObjectURL(url);
    }

    function toggleAutoRefresh() {
        if (autoRefresh.checked) {
            refreshInterval = setInterval(refreshLogs, 5000); // Refresh every 5 seconds
        } else {
            clearInterval(refreshInterval);
        }
    }

    function filterLogs() {
        updateLogDisplay();
    }

    function checkServiceStatus() {
        // Check API Gateway
        fetch('/api/health')
            .then(response => {
                statusElements.gateway.textContent = 'Online';
                statusElements.gateway.className = 'status-value online';
            })
            .catch(() => {
                statusElements.gateway.textContent = 'Offline';
                statusElements.gateway.className = 'status-value offline';
            });

        // Check Gemma 3
        fetch('/api/gemma3/models')
            .then(response => {
                statusElements.gemma.textContent = 'Online';
                statusElements.gemma.className = 'status-value online';
            })
            .catch(() => {
                statusElements.gemma.textContent = 'Offline';
                statusElements.gemma.className = 'status-value offline';
            });

        // Check DeepSeek-R1
        fetch('/api/deepseek/models')
            .then(response => {
                statusElements.deepseek.textContent = 'Online';
                statusElements.deepseek.className = 'status-value online';
            })
            .catch(() => {
                statusElements.deepseek.textContent = 'Offline';
                statusElements.deepseek.className = 'status-value offline';
            });
    }

    // Start auto-refresh if enabled
    if (autoRefresh.checked) {
        toggleAutoRefresh();
    }
}

// Navigation functionality
function initializeNavigation() {
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('nav a[href^="#"]');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const offsetTop = targetSection.offsetTop - 200; // Account for sticky header
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });

    // Add active class to navigation links based on scroll position
    const sections = document.querySelectorAll('section[id]');
    const navItems = document.querySelectorAll('nav a[href^="#"]');

    function updateActiveNav() {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop - 250;
            const sectionHeight = section.offsetHeight;
            if (window.scrollY >= sectionTop && window.scrollY < sectionTop + sectionHeight) {
                current = section.getAttribute('id');
            }
        });

        navItems.forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('href') === `#${current}`) {
                item.classList.add('active');
            }
        });
    }

    // Update active navigation on scroll
    window.addEventListener('scroll', updateActiveNav);
    updateActiveNav(); // Initial call

    // Add copy functionality to code blocks
    const codeBlocks = document.querySelectorAll('.code-block pre code');
    codeBlocks.forEach(codeBlock => {
        const copyButton = document.createElement('button');
        copyButton.textContent = 'Copy';
        copyButton.className = 'copy-btn';
        copyButton.style.cssText = `
            position: absolute;
            top: 10px;
            right: 10px;
            background: #3498db;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 3px;
            cursor: pointer;
            font-size: 12px;
            opacity: 0.7;
            transition: opacity 0.3s ease;
        `;

        const codeContainer = codeBlock.parentElement;
        codeContainer.style.position = 'relative';
        codeContainer.appendChild(copyButton);

        copyButton.addEventListener('click', function() {
            const text = codeBlock.textContent;
            navigator.clipboard.writeText(text).then(() => {
                copyButton.textContent = 'Copied!';
                copyButton.style.background = '#27ae60';
                setTimeout(() => {
                    copyButton.textContent = 'Copy';
                    copyButton.style.background = '#3498db';
                }, 2000);
            }).catch(err => {
                console.error('Failed to copy text: ', err);
                copyButton.textContent = 'Failed';
                copyButton.style.background = '#e74c3c';
                setTimeout(() => {
                    copyButton.textContent = 'Copy';
                    copyButton.style.background = '#3498db';
                }, 2000);
            });
        });

        copyButton.addEventListener('mouseenter', function() {
            this.style.opacity = '1';
        });

        copyButton.addEventListener('mouseleave', function() {
            this.style.opacity = '0.7';
        });
    });

    // Add search functionality
    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.placeholder = 'Search documentation...';
    searchInput.className = 'search-input';
    searchInput.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 10px 15px;
        border: 2px solid #3498db;
        border-radius: 25px;
        font-size: 14px;
        width: 250px;
        z-index: 1000;
        background: white;
        box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    `;

    document.body.appendChild(searchInput);

    searchInput.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase();
        const sections = document.querySelectorAll('section');
        
        sections.forEach(section => {
            const text = section.textContent.toLowerCase();
            if (text.includes(searchTerm) || searchTerm === '') {
                section.style.display = 'block';
            } else {
                section.style.display = 'none';
            }
        });
    });

    // Add keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // Ctrl/Cmd + K to focus search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            searchInput.focus();
        }
        
        // Escape to clear search
        if (e.key === 'Escape') {
            searchInput.value = '';
            searchInput.dispatchEvent(new Event('input'));
            searchInput.blur();
        }
    });
}
