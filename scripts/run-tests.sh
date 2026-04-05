#!/bin/bash
# Run backend tests and Docker builds locally before pushing.

set -e

echo "Running tests locally..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test backend
echo -e "${YELLOW}Testing backend...${NC}"
cd ../app/backend

# Install test dependencies if not present
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install -q -r requirements.txt pytest pytest-cov

# Run tests
pytest tests/ -v --cov=. --cov-report=term

# Check exit code
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backend tests passed!${NC}"
else
    echo -e "${RED}Backend tests failed!${NC}"
    exit 1
fi

deactivate
cd ../..

# Test Docker builds
echo -e "${YELLOW}Testing Docker builds...${NC}"
docker build -t backend-test ./app/backend
docker build -t frontend-test ./app/frontend

echo -e "${GREEN}Docker builds successful!${NC}"

# Cleanup
docker rmi backend-test frontend-test

echo -e "${GREEN}All tests passed!${NC}"