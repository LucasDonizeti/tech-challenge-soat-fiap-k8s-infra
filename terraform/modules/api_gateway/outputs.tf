output "api_gateway_execution_arn" {
  description = "ARN de execução do API Gateway necessário para permissões do Lambda"
  value       = aws_apigatewayv2_api.main_gateway.execution_arn
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_apigatewayv2_api.main_gateway.id
}

output "api_gateway_endpoint" {
  description = "Endpoint do API Gateway"
  value       = aws_apigatewayv2_api.main_gateway.api_endpoint
}

output "vpc_link_id" {
  description = "ID do VPC Link"
  value       = aws_apigatewayv2_vpc_link.eks_vpc_link.id
}

output "stage_id" {
  description = "ID do stage padrão"
  value       = aws_apigatewayv2_stage.default_stage.id
}
