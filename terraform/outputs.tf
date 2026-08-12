output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "URL do repositório ECR para a pipeline"
  value       = module.ecr.repository_url
}

output "database_subnets" {
  description = "Subnets privadas reservadas para o banco de dados"
  value       = module.vpc.database_subnets
}

output "db_subnet_group_name" {
  description = "Nome do grupo de subnets do banco de dados"
  value       = module.vpc.database_subnet_group
}

output "eks_node_security_group_id" {
  description = "Security Group ID do cluster EKS usado pelo RDS"
  value       = module.eks.node_security_group_id
}
