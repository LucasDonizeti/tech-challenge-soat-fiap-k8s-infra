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
  value       = module.ecr_oficina_api.repository_url
}

output "database_subnets" {
  description = "Subnets privadas reservadas para o banco de dados"
  value       = module.vpc.database_subnets
}

output "db_subnet_group_name" {
  description = "Nome do grupo de subnets do banco de dados"
  value       = module.vpc.database_subnet_group_name
}

output "eks_node_security_group_id" {
  description = "Security Group ID do cluster EKS usado pelo RDS"
  value       = module.eks.node_security_group_id
}

output "ecr_auth_lambda_url" {
  description = "URL do repositório ECR para o lambda authorizer"
  value       = module.ecr_auth_lambda.repository_url
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_gateway_id
}

output "api_gateway_execution_arn" {
  description = "ARN de execução do API Gateway para permissões do Lambda"
  value       = module.api_gateway.api_gateway_execution_arn
}

output "private_subnets" {
  description = "IDs das subnets privadas para Lambda"
  value       = module.vpc.private_subnets
}

output "newrelic_integration_role_arn" {
  description = "ARN da Role a ser colada no painel do New Relic"
  value       = module.new_relic.newrelic_integration_role_arn
}
