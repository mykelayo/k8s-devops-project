#!/bin/bash
# Health check script for all components

set -e

echo "Running health checks..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check pod status
check_pods() {
    local namespace=$1
    local label=$2
    local pods=$(kubectl get pods -n $namespace -l $label -o jsonpath='{.items[*].status.phase}')
    
    for status in $pods; do
        if [ "$status" != "Running" ]; then
            return 1
        fi
    done
    return 0
}

# Check devops-app namespace
echo -n "Checking backend pods... "
if check_pods devops-app "app=backend"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -n "Checking frontend pods... "
if check_pods devops-app "app=frontend"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check monitoring
echo -n "Checking Prometheus... "
if check_pods monitoring "app=kube-prometheus-stack-prometheus"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -n "Checking Grafana... "
if check_pods monitoring "app=kube-prometheus-stack-grafana"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -n "Checking Loki... "
if kubectl get pods -n monitoring -l app=loki -o jsonpath='{.items[*].status.phase}' | grep -q "Running"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Check Argo CD
echo -n "Checking Argo CD... "
if check_pods argocd "app.kubernetes.io/name=argocd-server"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# Test API endpoints
echo -n "Testing backend API... "
if kubectl run test-api --image=curlimages/curl -i --rm --restart=Never -- \
    curl -s -o /dev/null -w "%{http_code}" http://backend-service.devops-app:5000/api/health | grep -q "200"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

echo -e "${GREEN}Health check complete!${NC}"