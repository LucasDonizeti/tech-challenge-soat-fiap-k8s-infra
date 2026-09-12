variable "repository_name" {
  description = "Nome do repositório ECR"
  type        = string
}

variable "account_id" {
  description = "ID da conta AWS para configurar permissões"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
