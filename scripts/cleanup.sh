#!/bin/bash
# Complete cleanup script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}This will destroy ALL resources including the EKS cluster.${NC}"
read -p "Type 'yes' to continue: " confirm
if [ "$confirm" != "yes" ]; then
  echo -e "${YELLOW}Cancelled.${NC}"
  exit 0
fi

# 1. Remove Argo CD finalizer (prevents stuck resources)
echo -e "${YELLOW}Removing ArgoCD finalizer...${NC}"
kubectl patch application k8s-devops-project -n argocd \
  --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]' \
  --ignore-not-found=true 2>/dev/null || true

# 2. Delete namespaces
echo -e "${YELLOW}Deleting namespaces...${NC}"
kubectl delete namespace devops-app --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace monitoring --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace argocd --ignore-not-found=true 2>/dev/null || true

# 3. Let Terraform destroy everything else
echo -e "${YELLOW}Running terraform destroy...${NC}"
cd "$(dirname "$0")/../terraform"
terraform destroy -auto-approve

echo -e "${GREEN}Teardown complete.${NC}"