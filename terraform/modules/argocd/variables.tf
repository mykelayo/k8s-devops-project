variable "project_name" {
  description = "ArgoCD Application and repo secret name"
  type        = string
}

variable "environment" {
  description = "Environment overlay to sync (dev | staging | prod)"
  type        = string
}

variable "repo_url" {
  description = "HTTPS URL of the GitHub repository ArgoCD will watch"
  type        = string
}

variable "target_revision" {
  description = "Branch, tag, or commit SHA for ArgoCD to track"
  type        = string
}

variable "github_token" {
  description = "Fine-grained GitHub PAT with Contents."
  type      = string
  sensitive = true
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt hash of the ArgoCD admin password."
  type      = string
  sensitive = true
}

variable "argocd_webhook_secret" {
  description = "Shared secret between GitHub and ArgoCD for webhook payload validation."
  type      = string
  sensitive = true
}

variable "argocd_host" {
  description = "Public hostname for the ArgoCD server (e.g. argocd.yourdomain.com)."
  type    = string
  default = ""
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.0"
}
