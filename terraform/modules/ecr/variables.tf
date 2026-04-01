variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-devops-project"
}

variable "repositories" {
  description = "List of ECR repository names"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}