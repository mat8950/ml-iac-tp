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

variable "sites" {
  description = "Map of WordPress sites to deploy. Each key is a short site identifier (e.g. 'site1')."
  type = map(object({
    site_title  = string
    admin_user  = string
    admin_email = string
  }))
  default = {
    site1 = {
      site_title  = "WordPress Site 1"
      admin_user  = "admin"
      admin_email = "admin@site1.example.com"
    }
    site2 = {
      site_title  = "WordPress Site 2"
      admin_user  = "admin"
      admin_email = "admin@site2.example.com"
    }
  }
}
