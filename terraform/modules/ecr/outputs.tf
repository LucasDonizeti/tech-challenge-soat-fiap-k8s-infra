output "repository_url" {
  description = "URL do repositório ECR"
  value       = module.ecr.repository_url
}

output "repository_arn" {
  description = "ARN do repositório ECR"
  value       = module.ecr.repository_arn
}

output "repository_name" {
  description = "Nome do repositório ECR"
  value       = module.ecr.repository_name
}
