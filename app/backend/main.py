"""
A Simple Backend API for DevOps Dashboard
Returns system information and application status
"""

import os
import socket
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Application start time
START_TIME = datetime.now()

# In-memory counter for testing
visit_counter = 0

@app.route('/')
def home():
    """Root endpoint with API information"""
    return jsonify({
        "service": "DevOps Dashboard API",
        "version": "2.0.0",
        "status": "operational",
        "endpoints": [
            "/api/health",
            "/api/info",
            "/api/visits",
            "/api/env"
        ]
    })

@app.route('/api/health')
def health():
    """Health check endpoint for Kubernetes probes"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "backend-api"
    }), 200

@app.route('/api/info')
def info():
    """Returns system information"""
    global visit_counter
    visit_counter += 1
    
    return jsonify({
        "app_name": "DevOps Dashboard",
        "version": "2.0.0",
        "pod_name": socket.gethostname(),
        "pod_ip": socket.gethostbyname(socket.gethostname()),
        "hostname": socket.gethostname(),
        "environment": os.getenv('ENVIRONMENT', 'development'),
        "namespace": os.getenv('NAMESPACE', 'default'),
        "visits": visit_counter,
        "uptime_seconds": (datetime.now() - START_TIME).total_seconds(),
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/env')
def environment():
    """Returns environment variables (non-sensitive)"""
    safe_env = {
        "ENVIRONMENT": os.getenv('ENVIRONMENT', 'development'),
        "NAMESPACE": os.getenv('NAMESPACE', 'default'),
        "SERVICE_NAME": os.getenv('SERVICE_NAME', 'backend-service'),
        "REPLICA_ID": os.getenv('HOSTNAME', socket.gethostname())
    }
    return jsonify(safe_env)

@app.route('/api/headers')
def headers():
    """Returns request headers for debugging"""
    headers = dict(request.headers)
    return jsonify(headers)

@app.route('/api/reset')
def reset():
    """Reset visit counter (for testing)"""
    global visit_counter
    visit_counter = 0
    return jsonify({
        "message": "Counter reset",
        "visits": visit_counter
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)