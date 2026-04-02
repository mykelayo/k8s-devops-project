import pytest
import json
import sys
import os

# Add parent directory to path so Python can find main.py
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get('/api/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert 'service' in data

def test_info_endpoint(client):
    """Test info endpoint returns required fields"""
    response = client.get('/api/info')
    assert response.status_code == 200
    data = json.loads(response.data)
    
    # Check required fields exist
    assert 'app_name' in data
    assert 'version' in data
    assert 'pod_name' in data
    assert 'environment' in data
    assert 'visits' in data

def test_home_endpoint(client):
    """Test home endpoint returns API info"""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'service' in data
    assert 'endpoints' in data

def test_visit_counter_increments(client):
    """Test that visit counter increments"""
    response1 = client.get('/api/info')
    data1 = json.loads(response1.data)
    visits1 = data1['visits']
    
    response2 = client.get('/api/info')
    data2 = json.loads(response2.data)
    visits2 = data2['visits']
    
    assert visits2 == visits1 + 1

def test_reset_counter(client):
    """Test reset endpoint"""
    # First increment counter
    client.get('/api/info')
    client.get('/api/info')
    
    # Reset
    response = client.get('/api/reset')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['visits'] == 0
    
    # Verify reset
    info_response = client.get('/api/info')
    info_data = json.loads(info_response.data)
    assert info_data['visits'] == 1

def test_environment_endpoint(client):
    """Test environment variables endpoint"""
    response = client.get('/api/env')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'ENVIRONMENT' in data
    assert 'SERVICE_NAME' in data