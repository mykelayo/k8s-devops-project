# Outputs for connecting to the cluster and services

# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

# EKS outputs
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS worker nodes"
  value       = module.eks.node_security_group_id
}

# ECR outputs
output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "Names of ECR repositories"
  value       = module.ecr.repository_names
}

# IAM outputs
output "github_actions_user_name" {
  description = "Name of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.arn
}

# Utility outputs
output "kubeconfig_command" {
  description = "Command to update kubeconfig for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "aws_auth_configmap_command" {
  description = "Command to update aws-auth configmap"
  value       = "kubectl edit configmap aws-auth -n kube-system"
}