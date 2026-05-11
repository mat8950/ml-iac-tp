variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address. Defaults to subnet setting"
  type        = bool
  default     = null
}

variable "volume_type" {
  description = "Root volume type (gp2, gp3, io1, ...)"
  type        = string
  default     = "gp3"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on first boot"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach to the instance"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to the instance"
  type        = map(string)
  default     = {}
}
