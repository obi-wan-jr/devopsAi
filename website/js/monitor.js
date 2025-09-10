// Monitor-only JavaScript for AI System Administrator Agent Dashboard
// Handles only the monitor functionality, no chat interface

document.addEventListener('DOMContentLoaded', function() {
    // Update last updated timestamp
    const lastUpdatedElement = document.getElementById('lastUpdated');
    if (lastUpdatedElement) {
        lastUpdatedElement.textContent = new Date().toLocaleString();
    }
    
    // Initialize monitor functionality
    initializeMonitor();
});

function initializeMonitor() {
    console.log('Monitor interface initialized');
    
    // Add any monitor-specific functionality here
    // For now, just log that the monitor is ready
    console.log('System monitor ready');
}
