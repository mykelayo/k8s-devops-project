resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)
  
  name = "${var.project_name}-${each.value}-${var.environment}"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.value}-repo"
    Repository  = each.value
    Environment = var.environment
  })
}

# Lifecycle policy to clean up old images
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each = aws_ecr_repository.repos
  
  repository = each.value.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
