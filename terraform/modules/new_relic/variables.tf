variable "tags" {
  description = "Tags para identificação dos recursos"
  type        = map(string)
  default     = {}
}

variable "newrelic_license_key" {
  type      = string
  sensitive = true
}