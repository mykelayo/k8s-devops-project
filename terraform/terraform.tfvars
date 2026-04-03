aws_region = "us-east-1"
project_name = "k8s-devops-project"
environment = "dev"

vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

cluster_name = "k8s-devops-project"
cluster_version = "1.32"
node_instance_types = ["m7i-flex.large"]
desired_node_count = 2
min_node_count = 1
max_node_count = 3

ecr_repositories = ["backend", "frontend"]

tags = {
  "Project"     = "K8s-DevOps-Project"
  "Owner"       = "Michael"
  "ManagedBy"   = "Terraform"
  "Environment" = "Dev"
}