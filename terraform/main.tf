# Our main configuration that calls all modules

module "vpc" {
  source = "./modules/networking"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  
  tags = var.tags
}

# EKS Module - Kubernetes cluster
module "eks" {
  source = "./modules/eks"
  
  cluster_name           = var.cluster_name
  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  node_instance_types    = var.node_instance_types
  desired_node_count     = var.desired_node_count
  min_node_count         = var.min_node_count
  max_node_count         = var.max_node_count
  environment            = var.environment
  
  depends_on = [module.vpc]
}

# ECR Module - Container registries
module "ecr" {
  source = "./modules/ecr"
  
  repositories = var.ecr_repositories
  environment  = var.environment
  
  tags = var.tags
}

# Security Group for additional services
resource "aws_security_group" "additional" {
  name        = "${var.project_name}-additional-sg-${var.environment}"
  description = "Additional security group for monitoring and ingress"
  vpc_id      = module.vpc.vpc_id
  
  # Allow HTTPS from anywhere (for ALB)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow HTTP from anywhere (for ALB redirect)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-additional-sg"
  })
}

# Create IAM role for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-${var.environment}"
  
  tags = merge(var.tags, {
    Name = "GitHub Actions User"
  })
}

resource "aws_iam_user_policy" "github_actions_ecr" {
  name = "github-actions-ecr-policy"
  user = aws_iam_user.github_actions.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}