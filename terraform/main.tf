module "vpc" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  tags = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  node_instance_types = var.node_instance_types
  desired_node_count  = var.desired_node_count
  min_node_count      = var.min_node_count
  max_node_count      = var.max_node_count
  environment         = var.environment
  admin_role_arn      = var.admin_role_arn

  depends_on = [module.vpc]
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  repositories = var.ecr_repositories
  environment  = var.environment

  tags = var.tags
}

module "argocd" {
  source = "./modules/argocd"

  project_name                 = var.project_name
  environment                  = var.environment
  repo_url                     = var.repo_url
  target_revision              = var.target_revision
  github_token                 = var.github_token
  argocd_admin_password_bcrypt = var.argocd_admin_password_bcrypt
  argocd_webhook_secret        = var.argocd_webhook_secret
  argocd_host                  = var.argocd_host
  argocd_chart_version         = var.argocd_chart_version

  depends_on = [module.eks]
}

# ── Security group for ALB / ingress ──────────────────────────────────────────

resource "aws_security_group" "additional" {
  name        = "${var.project_name}-additional-sg-${var.environment}"
  description = "Security group for monitoring and ingress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# ── GitHub Actions IAM user ───────────────────────────────────────────────────
# The CI only needs to push images to ECR. It never touches the cluster.
# ArgoCD handles all cluster interaction.

resource "aws_iam_user" "github_actions" {
  name = "github-actions-${var.environment}"

  tags = merge(var.tags, {
    Name = "GitHub Actions CI User"
  })
}

resource "aws_iam_user_policy" "github_actions_ecr" {
  name = "github-actions-ecr-policy"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
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
          "ecr:PutImage",
        ]
        Resource = "*"
      },
    ]
  })
}
