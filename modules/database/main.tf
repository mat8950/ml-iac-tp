locals {
  ssh_rules = length(var.allowed_ssh_cidrs) > 0 ? [{
    description     = "SSH from allowed CIDRs"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.allowed_ssh_cidrs
    security_groups = []
  }] : []

  ssh_from_wp_sg_rules = length(var.wordpress_sg_ids) > 0 ? [{
    description     = "SSH from WordPress SG (Ansible bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = var.wordpress_sg_ids
  }] : []

  mysql_from_sg_rules = length(var.wordpress_sg_ids) > 0 ? [{
    description     = "MySQL from WordPress SG"
    from_port       = var.mysql_port
    to_port         = var.mysql_port
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = var.wordpress_sg_ids
  }] : []

  mysql_from_cidr_rules = length(var.allowed_mysql_cidrs) > 0 ? [{
    description     = "MySQL from allowed CIDRs"
    from_port       = var.mysql_port
    to_port         = var.mysql_port
    protocol        = "tcp"
    cidr_blocks     = var.allowed_mysql_cidrs
    security_groups = []
  }] : []
}

module "sg" {
  source = "../security_group"

  name        = "${var.name}-sg"
  description = "Security group for DB instance ${var.name}"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress_rules = concat(
    local.mysql_from_sg_rules,
    local.mysql_from_cidr_rules,
    local.ssh_rules,
    local.ssh_from_wp_sg_rules,
    var.extra_ingress_rules
  )
}

module "instance" {
  source = "../ec2_instance"

  name                 = var.name
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_group_ids   = [module.sg.security_group_id]
  key_name             = var.key_name
  volume_type          = var.volume_type
  volume_size          = var.volume_size
  volume_encrypted     = false
  user_data            = var.user_data
  iam_instance_profile = var.iam_instance_profile
  tags                 = var.tags
}
