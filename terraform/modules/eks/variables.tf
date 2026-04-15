variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of public subnets"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
}

variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "admin_role_arn" {
  description = "IAM user or role ARN to grant cluster admin access"
  type        = string
}
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lbc_chart_version" {
  description = "Helm chart version for the AWS Load Balancer Controller"
  type        = string
  default     = "1.11.0"
}
