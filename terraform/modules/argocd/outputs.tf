output "argocd_namespace_v1" {
  description = "Kubernetes namespace ArgoCD is installed in"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_application_name" {
  description = "Name of the ArgoCD Application resource"
  value       = kubernetes_manifest.argocd_app.manifest.metadata.name
}

output "argocd_access_command" {
  description = "Port-forward command to reach the ArgoCD UI locally"
  value       = "kubectl port-forward -n argocd svc/argocd-server 8080:80"
}

output "argocd_initial_password_command" {
  description = "Command to fetch the initial admin password (only present if no custom password was set)"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "github_webhook_url" {
  description = "URL to register as the GitHub webhook payload URL (only useful when argocd_host is set)"
  value       = var.argocd_host != "" ? "https://${var.argocd_host}/api/webhook" : "No host configured. ArgoCD will poll every 3 minutes"
}
