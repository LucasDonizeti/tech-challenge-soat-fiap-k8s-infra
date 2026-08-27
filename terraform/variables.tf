variable "region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Nome da aplicação (usado como prefixo nos recursos)"
  type        = string
  default     = "oficina"
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "newrelic_account_id" {
  description = "ID da conta do New Relic"
  type        = string
}

variable "newrelic_api_key" {
  description = "User/Personal API Key do New Relic para automação via Terraform"
  type        = string
  sensitive   = true
}

variable "newrelic_license_key" {
  description = "License Key de Ingestão do New Relic (Ingest - License)"
  type        = string
  sensitive   = true
}