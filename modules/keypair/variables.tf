variable "name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "rsa_bits" {
  description = "Size of the RSA key in bits"
  type        = number
  default     = 4096
}

variable "private_key_output_path" {
  description = "Local path where the private key .pem file will be saved"
  type        = string
  default     = "."
}

variable "tags" {
  description = "Tags to apply to the key pair"
  type        = map(string)
  default     = {}
}
