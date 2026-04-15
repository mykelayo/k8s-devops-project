#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Testing backend..."
cd "$SCRIPT_DIR/../app/backend"

if [ ! -d "venv" ]; then
  python3 -m venv venv
fi

source venv/bin/activate
pip install -q -r requirements.txt pytest pytest-cov
pytest tests/ -v --cov=. --cov-report=term
deactivate

echo "Building images..."
docker build -t backend-test "$SCRIPT_DIR/../app/backend"
docker build -t frontend-test "$SCRIPT_DIR/../app/frontend"

echo "Cleaning up..."
docker rmi backend-test frontend-test

echo "Done."