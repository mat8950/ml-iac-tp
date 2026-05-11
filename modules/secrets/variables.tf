variable "prefix" {
  description = "Prefix used for secret naming (e.g. 'mathis')"
  type        = string
}

variable "ssh_keys" {
  description = "Map of machine name → private key PEM to store in Secrets Manager"
  type        = map(string)
  default     = {}
  sensitive   = true
}
