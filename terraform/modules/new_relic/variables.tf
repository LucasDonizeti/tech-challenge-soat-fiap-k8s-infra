variable "tags" {
  description = "Tags para identificação dos recursos"
  type        = map(string)
  default     = {}
}

variable "newrelic_license_key" {
  type      = string
  sensitive = true
}

variable "api_endpoint" {
  description = "URL base do API Gateway para a verificação de healthcheck"
  type        = string
}