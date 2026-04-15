// DevOps Dashboard Frontend Application
// Fetches data from backend API and updates UI

const API_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5000'  
    : '';  

// DOM Elements
const elements = {
    podName: document.getElementById('podName'),
    podIP: document.getElementById('podIP'),
    hostname: document.getElementById('hostname'),
    environment: document.getElementById('environment'),
    uptime: document.getElementById('uptime'),
    visits: document.getElementById('visits'),
    serviceName: document.getElementById('serviceName'),
    replicaId: document.getElementById('replicaId'),
    timestamp: document.getElementById('timestamp'),
    apiVersion: document.getElementById('apiVersion'),
    colorBox: document.getElementById('colorBox'),
    namespaceBadge: document.getElementById('namespaceBadge'),
    statusDot: document.getElementById('statusDot'),
    statusText: document.getElementById('statusText')
};

// Helper function to format uptime
function formatUptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

// Fetch system info
async function fetchSystemInfo() {
    try {
        const response = await fetch(`${API_URL}/api/info`);
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();
        
        elements.podName.textContent = data.pod_name || data.hostname;
        elements.podIP.textContent = data.pod_ip || 'N/A';
        elements.hostname.textContent = data.hostname;
        elements.environment.textContent = data.environment.toUpperCase();
        elements.visits.textContent = data.visits;
        elements.uptime.textContent = formatUptime(data.uptime_seconds);
        elements.timestamp.textContent = new Date(data.timestamp).toLocaleString();
        elements.apiVersion.textContent = data.version;
        
        // Update color from environment if set
        if (data.app_color) {
            elements.appColor.textContent = data.app_color;
            elements.colorBox.style.backgroundColor = data.app_color;
        }
        
        return data;
    } catch (error) {
        console.error('Error fetching system info:', error);
        updateStatus(false, 'Failed to fetch system info');
        return null;
    }
}

// Fetch environment variables
async function fetchEnvironment() {
    try {
        const response = await fetch(`${API_URL}/api/env`);
        if (!response.ok) throw new Error('Network response was not ok');
        const data = await response.json();
        
        elements.serviceName.textContent = data.SERVICE_NAME;
        elements.replicaId.textContent = data.REPLICA_ID;
        elements.namespaceBadge.textContent = `Namespace: ${data.NAMESPACE}`;
        
        return data;
    } catch (error) {
        console.error('Error fetching environment:', error);
        return null;
    }
}

// Reset counter
async function resetCounter() {
    try {
        const response = await fetch(`${API_URL}/api/reset`);
        if (!response.ok) throw new Error('Failed to reset counter');
        const data = await response.json();
        elements.visits.textContent = data.visits;
        updateStatus(true, 'Counter reset successfully!');
        
        // Reset status message after 3 seconds
        setTimeout(() => {
            if (elements.statusText.textContent === 'Counter reset successfully!') {
                updateStatus(true, 'Connected to backend');
            }
        }, 3000);
    } catch (error) {
        console.error('Error resetting counter:', error);
        updateStatus(false, 'Failed to reset counter');
    }
}

// Update connection status
function updateStatus(isHealthy, message) {
    if (isHealthy) {
        elements.statusDot.classList.add('healthy');
        elements.statusText.textContent = message || 'Connected to backend';
    } else {
        elements.statusDot.classList.remove('healthy');
        elements.statusText.textContent = message || 'Backend connection failed';
    }
}

// Check backend health
async function checkHealth() {
    try {
        const response = await fetch(`${API_URL}/api/health`);
        if (response.ok) {
            updateStatus(true, 'Connected to backend');
            return true;
        } else {
            throw new Error('Health check failed');
        }
    } catch (error) {
        console.error('Health check failed:', error);
        updateStatus(false, 'Backend unreachable');
        return false;
    }
}

// Refresh all data
async function refreshData() {
    updateStatus(true, 'Refreshing data...');
    
    const [systemInfo, envInfo, health] = await Promise.all([
        fetchSystemInfo(),
        fetchEnvironment(),
        checkHealth()
    ]);
    
    if (systemInfo && envInfo && health) {
        updateStatus(true, 'Data updated successfully');
    }
}

// Initialize the dashboard
async function init() {
    // Set initial status
    updateStatus(false, 'Connecting to backend...');
    
    // Initial data fetch
    await refreshData();
    
    // Set up auto-refresh every 10 seconds
    setInterval(refreshData, 10000);
    
    // Set up event listeners
    const resetBtn = document.getElementById('resetBtn');
    if (resetBtn) {
        resetBtn.addEventListener('click', resetCounter);
    }
    
    const refreshBtn = document.getElementById('refreshBtn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', refreshData);
    }
}

// Start the application when DOM is loaded
document.addEventListener('DOMContentLoaded', init);