#!/bin/bash
# Complete cleanup script for all resources

set -e

echo "Starting cleanup process..."

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Confirm cleanup
read -p "${RED}This will delete ALL resources (EKS cluster, Argo CD, monitoring, etc.). Continue? (yes/no): ${NC}" confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

# 1. Delete Argo CD applications
echo -e "${YELLOW}Deleting Argo CD applications...${NC}"
kubectl delete application devops-app -n argocd --ignore-not-found=true

# 2. Delete Kubernetes resources
echo -e "${YELLOW}Deleting Kubernetes resources...${NC}"
kubectl delete namespace devops-app --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# 3. Clean up Helm releases
echo -e "${YELLOW}Cleaning up Helm releases...${NC}"
helm uninstall kube-prometheus-stack -n monitoring --ignore-not-found
helm uninstall loki -n monitoring --ignore-not-found

# 4. Delete CRDs
echo -e "${YELLOW}Deleting CRDs...${NC}"
kubectl delete crd applications.argoproj.io --ignore-not-found=true
kubectl delete crd appprojects.argoproj.io --ignore-not-found=true
kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found=true
kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found=true

# 5. Destroy Terraform infrastructure
if [ -d "terraform" ]; then
    echo -e "${YELLOW}Destroying Terraform infrastructure...${NC}"
    cd terraform
    terraform destroy -auto-approve
    cd ..
fi

# 6. Clean up Docker images
read -p "${YELLOW}Remove local Docker images? (yes/no): ${NC}" clean_docker
if [ "$clean_docker" = "yes" ]; then
    echo -e "${YELLOW}Removing Docker images...${NC}"
    docker rmi app-backend app-frontend --force || true
fi

echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${YELLOW}Note: AWS resources (EKS, ECR, etc.) have been destroyed if Terraform was used.${NC}"