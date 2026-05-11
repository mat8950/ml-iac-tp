variable "name" {
  description = "Name tag for the DB instance and its security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID where the instance will be deployed"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp2"
}

variable "volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 10
}

variable "mysql_port" {
  description = "MySQL/MariaDB port"
  type        = number
  default     = 3306
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = []
}

variable "allowed_mysql_cidrs" {
  description = "Additional CIDR blocks allowed on the MySQL port (e.g. admin IP)"
  type        = list(string)
  default     = []
}

variable "wordpress_sg_ids" {
  description = "Security group IDs of WordPress instances allowed to reach MySQL"
  type        = list(string)
  default     = []
}

variable "extra_ingress_rules" {
  description = "Additional ingress rules to add to the DB security group"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
  }))
  default = []
}

variable "user_data" {
  description = "User data script executed on first boot (e.g. DB install/config)"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile to attach"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
