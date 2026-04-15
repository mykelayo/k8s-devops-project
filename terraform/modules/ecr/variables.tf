variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names"
  type        = list(string)
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