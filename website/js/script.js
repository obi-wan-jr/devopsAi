// AI System Administrator Agent Documentation JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Set last updated timestamp
    const lastUpdated = document.getElementById('lastUpdated');
    if (lastUpdated) {
        lastUpdated.textContent = new Date().toLocaleString();
    }

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

    // Add health check functionality
    const healthCheckButton = document.createElement('button');
    healthCheckButton.textContent = 'Check System Health';
    healthCheckButton.className = 'health-check-btn';
    healthCheckButton.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: #27ae60;
        color: white;
        border: none;
        padding: 15px 20px;
        border-radius: 50px;
        cursor: pointer;
        font-size: 14px;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
        z-index: 1000;
        transition: all 0.3s ease;
    `;

    document.body.appendChild(healthCheckButton);

    healthCheckButton.addEventListener('click', function() {
        this.textContent = 'Checking...';
        this.style.background = '#f39c12';
        
        // Check API Gateway health
        fetch('http://meatpi:8080/health')
            .then(response => response.json())
            .then(data => {
                this.textContent = '✅ System Healthy';
                this.style.background = '#27ae60';
                setTimeout(() => {
                    this.textContent = 'Check System Health';
                    this.style.background = '#27ae60';
                }, 3000);
            })
            .catch(error => {
                this.textContent = '❌ System Down';
                this.style.background = '#e74c3c';
                setTimeout(() => {
                    this.textContent = 'Check System Health';
                    this.style.background = '#27ae60';
                }, 3000);
            });
    });

    healthCheckButton.addEventListener('mouseenter', function() {
        this.style.transform = 'scale(1.05)';
    });

    healthCheckButton.addEventListener('mouseleave', function() {
        this.style.transform = 'scale(1)';
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

    // Add tooltip for keyboard shortcuts
    const tooltip = document.createElement('div');
    tooltip.textContent = 'Press Ctrl+K to search';
    tooltip.className = 'tooltip';
    tooltip.style.cssText = `
        position: fixed;
        bottom: 80px;
        right: 20px;
        background: #2c3e50;
        color: white;
        padding: 8px 12px;
        border-radius: 5px;
        font-size: 12px;
        z-index: 1000;
        opacity: 0;
        transition: opacity 0.3s ease;
    `;

    document.body.appendChild(tooltip);

    // Show tooltip on page load
    setTimeout(() => {
        tooltip.style.opacity = '1';
        setTimeout(() => {
            tooltip.style.opacity = '0';
        }, 3000);
    }, 1000);
});