variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-devops-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# EKS Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "k8s-devops-project"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

# ECR Variables
variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}

# Tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default = {
    "Project"     = "K8s-DevOps-Project"
    "Owner"       = "Michael"
    "ManagedBy"   = "Terraform"
    "Environment" = "Dev"
  }
}

# ArgoCD

variable "repo_url" {
  description = "HTTPS URL of the GitHub repo ArgoCD watches"
  type        = string
  default     = "https://github.com/mykelayo/k8s-devops-project"
}

variable "target_revision" {
  description = "Branch ArgoCD tracks"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "Fine-grained GitHub PAT."
  type        = string
  sensitive   = true
}

variable "argocd_admin_password_bcrypt" {
  description = "Bcrypt hash of ArgoCD admin password."
  type        = string
  sensitive   = true
}

variable "argocd_webhook_secret" {
  description = "Shared secret for GitHub webhook validation."
  type        = string
  sensitive   = true
}

variable "argocd_host" {
  description = "Public hostname for ArgoCD ingress (e.g. argocd.yourdomain.com)."
  type        = string
  default     = ""
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.0"
}

variable "admin_role_arn" {
  description = "IAM user or role ARN to grant cluster admin access"
  type        = string
}