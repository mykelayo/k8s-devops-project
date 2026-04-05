#!/bin/bash
# Health check for all cluster components.

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}OK${NC}"; }
fail() { echo -e "${RED}FAILED${NC}"; }

echo -e "${YELLOW}Monitoring...${NC}"

# Function to check pod status

check_pods() {
  local namespace=$1
  local label=$2
  local statuses
  statuses=$(kubectl get pods -n "$namespace" -l "$label" \
    -o jsonpath='{.items[*].status.phase}' 2>/dev/null)

  if [ -z "$statuses" ]; then
    return 1
  fi

  for status in $statuses; do
    [ "$status" = "Running" ] || return 1
  done
  return 0
}

# Check devops-app namespace

echo -e "${YELLOW}Application...${NC}"
echo -n "Backend pods:   "; check_pods devops-app "app=backend"   && pass || fail
echo -n "Frontend pods:  "; check_pods devops-app "app=frontend"  && pass || fail

# Check monitoring

echo ""
echo -e "${YELLOW}Monitoring...${NC}"
echo -n "Prometheus:     "; check_pods monitoring "app.kubernetes.io/name=prometheus"  && pass || fail
echo -n "Grafana:        "; check_pods monitoring "app.kubernetes.io/name=grafana"     && pass || fail
echo -n "Loki:           "; check_pods monitoring "app=loki"                           && pass || fail

# Check Argo CD

echo ""
echo -e "${YELLOW}ArgoCD...NC}"
echo -n "ArgoCD server:  "; check_pods argocd "app.kubernetes.io/name=argocd-server"  && pass || fail
echo -n "Repo server:    "; check_pods argocd "app.kubernetes.io/name=argocd-repo-server" && pass || fail

echo ""
echo -e "${YELLOW}ArgoCD sync status...${NC}"
SYNC_STATUS=$(kubectl get application k8s-devops-project -n argocd \
  -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
HEALTH_STATUS=$(kubectl get application k8s-devops-project -n argocd \
  -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

echo "Sync:   $SYNC_STATUS"
echo "Health: $HEALTH_STATUS"

echo ""
echo -e "${YELLOW}Backend API...${NC}"
echo -n "Health endpoint: "
HTTP_CODE=$(kubectl run health-probe-$RANDOM \
  --image=curlimages/curl --restart=Never -i --rm --quiet -- \
  curl -s -o /dev/null -w "%{http_code}" \
  http://backend-service.devops-app:5000/api/health 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then pass; else echo -e "${RED}$HTTP_CODE${NC}"; fi

echo ""
echo -e "${GREEN}Health check complete.${NC}"
