variable "name" {
  description = "Name used as prefix for all network resources (e.g. 'myproject-prod')"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Enable DNS resolution in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Explicit list of AZs to use. Defaults to all available AZs in the region"
  type        = list(string)
  default     = []
}

variable "public_subnet_newbits" {
  description = "Bits added to vpc_cidr prefix to size public subnets"
  type        = number
  default     = 8
}

variable "private_subnet_newbits" {
  description = "Bits added to vpc_cidr prefix to size private subnets"
  type        = number
  default     = 8
}

variable "private_subnet_netnum_offset" {
  description = "netnum offset for private subnets to avoid overlap with public ones"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
