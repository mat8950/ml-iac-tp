variable "prefix" {
  description = "Prefix used for secret naming (e.g. 'mathis')"
  type        = string
}

variable "ssh_key_wordpress" {
  description = "Private key PEM for the WordPress instance"
  type        = string
  sensitive   = true
}

variable "ssh_key_db" {
  description = "Private key PEM for the DB instance"
  type        = string
  sensitive   = true
}
