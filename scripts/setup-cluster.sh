#!/bin/bash
# Cluster setup script with monitoring and Argo CD

set -e

echo "Setting up Kubernetes cluster with monitoring and GitOps..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED} kubectl not configured. Please configure your cluster first.${NC}"
    exit 1
fi

# 1. Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl create namespace devops-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Deploy Prometheus Stack
echo -e "${YELLOW}Deploying Prometheus stack...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin \
  --set grafana.service.type=ClusterIP \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.scrapeInterval=30s \
  --set alertmanager.enabled=true \
  --wait

# 3. Deploy Loki stack
echo -e "${YELLOW}Deploying Loki stack...${NC}"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi \
  --wait

# 4. Deploy Argo CD
echo -e "${YELLOW}Deploying Argo CD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo -e "${YELLOW}Waiting for Argo CD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 5. Create Argo CD Application
echo -e "${YELLOW}Creating Argo CD application...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: devops-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/mykelayo/k8s-devops-project
    targetRevision: main
    path: kubernetes/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: devops-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

# 6. Apply custom monitoring configurations
echo -e "${YELLOW}Applying monitoring configurations...${NC}"
kubectl apply -f kubernetes/monitoring/ -n monitoring

# 7. Get Argo CD password
echo -e "${GREEN}Cluster setup complete!${NC}"
echo ""
echo -e "${YELLOW}Argo CD Login Credentials:${NC}"
echo "URL: kubectl port-forward -n argocd service/argocd-server 8080:443"
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo -e "${YELLOW}Grafana Access:${NC}"
echo "URL: kubectl port-forward -n monitoring service/kube-prometheus-stack-grafana 3000:80"
echo "Username: admin"
echo "Password: admin"
echo ""
echo -e "${YELLOW}Loki Logs:${NC}"
echo "Access logs via Grafana: Add Loki data source with URL: http://loki:3100"
echo ""