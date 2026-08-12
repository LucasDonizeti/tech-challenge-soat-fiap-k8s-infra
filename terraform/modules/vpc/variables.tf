variable "name" { type = string }
variable "cidr" { type = string }
variable "azs" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "database_subnets" {
  type    = list(string)
  default = []
}
variable "cluster_name" {
  description = "Nome do cluster EKS para as tags das subnets"
  type        = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
