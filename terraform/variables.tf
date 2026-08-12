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
