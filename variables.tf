variable "aws_region" {
  description = "AWS region to deploy resources in (e.g. eu-west-1, us-east-1)"
  type        = string
  default     = "eu-west-1"
}

variable "prefix" {
  description = "Unique prefix for all resource names — use your firstname/alias, no spaces"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet (true during Ansible provisioning only)"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the instances"
  type        = list(string)
  default     = []
}
