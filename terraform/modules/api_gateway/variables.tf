variable "name" {
  description = "Nome do API Gateway"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC para criar o security group do VPC Link"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC para restringir o security group"
  type        = string
}

variable "private_subnets" {
  description = "IDs das subnets privadas para o VPC Link"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
