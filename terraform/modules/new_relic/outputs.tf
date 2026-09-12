output "newrelic_integration_role_arn" {
  description = "ARN da LabRole configurada para a integração AWS com o New Relic"
  value       = data.aws_iam_role.lab_role.arn
}