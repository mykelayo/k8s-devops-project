#!/bin/bash
set -euo pipefail

echo "WARNING: This will destroy all resources including the EKS cluster."
read -p "Type 'yes' to continue: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi

cd "$(dirname "$0")/../terraform"

echo "Removing ArgoCD Application resources from Terraform state..."
terraform state rm "module.argocd.kubernetes_manifest.argocd_app" 2>/dev/null || true
terraform state rm "module.argocd.kubernetes_manifest.argocd_monitoring_app" 2>/dev/null || true

echo "Deleting ArgoCD Applications..."
kubectl delete application "${PROJECT_NAME}" -n argocd \
  --ignore-not-found --wait=false 2>/dev/null || true
kubectl delete application "${PROJECT_NAME}-monitoring" -n argocd \
  --ignore-not-found --wait=false 2>/dev/null || true

echo "Waiting for ArgoCD to drain managed resources..."
sleep 30

echo "Deleting ingress to release ALB..."
kubectl delete ingress -n devops-app --all --ignore-not-found 2>/dev/null || true

echo "Waiting for ALB to be released..."
sleep 30

echo "Uninstalling monitoring stack..."
helm uninstall kube-prometheus-stack -n monitoring --ignore-not-found 2>/dev/null || true
helm uninstall loki -n monitoring --ignore-not-found 2>/dev/null || true
sleep 15

echo "Uninstalling ArgoCD..."
helm uninstall argocd -n argocd --ignore-not-found 2>/dev/null || true

echo "Removing ArgoCD CRDs..."
kubectl delete crd \
  applications.argoproj.io \
  applicationsets.argoproj.io \
  appprojects.argoproj.io \
  --ignore-not-found 2>/dev/null || true

echo "Removing monitoring CRDs..."
kubectl delete crd \
  alertmanagerconfigs.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  podmonitors.monitoring.coreos.com \
  probes.monitoring.coreos.com \
  prometheuses.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  thanosrulers.monitoring.coreos.com \
  --ignore-not-found 2>/dev/null || true

for ns in devops-app monitoring argocd; do
  echo "Deleting namespace: $ns"
  kubectl patch namespace "$ns" \
    -p '{"metadata":{"finalizers":[]}}' \
    --type=merge --ignore-not-found 2>/dev/null || true
  kubectl delete namespace "$ns" --ignore-not-found --wait=false 2>/dev/null || true
done

echo "Waiting for namespaces to terminate..."
for ns in devops-app monitoring argocd; do
  kubectl wait --for=delete namespace/"$ns" --timeout=60s 2>/dev/null || true
done

# echo "Removing kubernetes manifest from terraform state..."

# terraform state rm "module.argocd.kubernetes_manifest.argocd_app" 2>/dev/null || true
# terraform state rm "module.argocd.kubernetes_manifest.argocd_monitoring_app" 2>/dev/null || true

echo "Running terraform destroy..."
terraform destroy \
  -target=module.monitoring \
  -target=module.argocd.helm_release.argocd \
  -target=module.argocd.kubernetes_secret_v1.argocd_repo \
  -target=module.argocd.kubernetes_namespace_v1.argocd \
  -target=module.eks \
  -target=module.vpc \
  -target=module.ecr \
  -target=aws_iam_user.github_actions \
  -target=aws_iam_user_policy.github_actions_ecr \
  -target=aws_security_group.additional \
  -target=aws_eks_access_entry.admin \
  -target=aws_eks_access_policy_association.admin \
  -auto-approve

echo "Teardown complete."