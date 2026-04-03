output "repository_urls" {
  description = "URLs of ECR repositories"
  value = {
    for k, repo in aws_ecr_repository.repos : k => repo.repository_url
  }
}

output "repository_names" {
  description = "Names of ECR repositories"
  value = {
    for k, repo in aws_ecr_repository.repos : k => repo.name
  }
}

output "repository_arns" {
  description = "ARNs of ECR repositories"
  value = {
    for k, repo in aws_ecr_repository.repos : k => repo.arn
  }
  
}
output "ecr_repository_names" {
  description = "Names of ECR repositories"
  value = {
    backend  = aws_ecr_repository.repos["backend"].name
    frontend = aws_ecr_repository.repos["frontend"].name
  }
}

output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value = {
    backend  = aws_ecr_repository.repos["backend"].repository_url
    frontend = aws_ecr_repository.repos["frontend"].repository_url
  }
}