# ── Migration d'état (à supprimer après le premier apply réussi) ──────────────
# Indique à Terraform que module.keypair a été renommé en keypair_wordpress.
# keypair_db est nouveau (clé dédiée à la DB).

moved {
  from = module.keypair
  to   = module.keypair_wordpress
}

# ── Locals ───────────────────────────────────────────────────────────────────

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the instances."
  type        = list(string)
  default = [
    "37.165.169.117/32",         # Mathis
    "82.65.78.207/32",           # Alexandre
    "82.65.78.207/32",           # Nino
  ]
}

locals {
  prefix = "mathis"

  name = {
    vpc        = "${local.prefix}-vpc-iac"
    igw        = "${local.prefix}-igw-iac"
    wp         = "${local.prefix}-wp-iac"
    db         = "${local.prefix}-db-iac"
    sg_wp      = "${local.prefix}-sg-wp-iac"
    sg_db      = "${local.prefix}-sg-db-iac"
    keypair_wp = "${local.prefix}-keypair-wp-iac"
    keypair_db = "${local.prefix}-keypair-db-iac"
  }
}

# ── Data sources ──────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Couche 1 : Infrastructure de base ────────────────────────────────────────

resource "random_id" "s3_suffix" {
  byte_length = 4
}

module "network" {
  source = "./modules/network"

  name     = local.prefix
  vpc_cidr = "10.0.0.0/16"
}

module "s3_media" {
  source = "./modules/s3_bucket"

  bucket_name        = "${local.prefix}-s3-iac-${random_id.s3_suffix.hex}"
  versioning_enabled = true
  sse_algorithm      = "AES256"

  tags = {
    Name = "${local.prefix}-s3-iac"
  }
}

# ── Couche 2 : Sécurité & Identité ───────────────────────────────────────────

module "keypair_wordpress" {
  source = "./modules/keypair"

  name                    = local.name.keypair_wp
  private_key_output_path = "${path.module}/keys"
}

module "keypair_db" {
  source = "./modules/keypair"

  name                    = local.name.keypair_db
  private_key_output_path = "${path.module}/keys"
}

module "secrets" {
  source = "./modules/secrets"

  prefix = local.prefix

  ssh_key_wordpress = module.keypair_wordpress.private_key_pem
  ssh_key_db        = module.keypair_db.private_key_pem
}

# ── Couche 3 : Application ────────────────────────────────────────────────────

module "wordpress" {
  source = "./modules/wordpress"

  name              = local.name.wp
  vpc_id            = module.network.vpc_id
  subnet_id         = module.network.public_subnet_ids[0]
  ami_id            = data.aws_ami.al2023.id
  key_name          = module.keypair_wordpress.key_name
  allowed_ssh_cidrs = var.ssh_allowed_cidrs
}

# ── Couche 4 : Données ────────────────────────────────────────────────────────

module "db" {
  source = "./modules/database"

  name                = local.name.db
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.private_subnet_ids[0]
  ami_id              = data.aws_ami.al2023.id
  key_name            = module.keypair_db.key_name
  allowed_ssh_cidrs   = var.ssh_allowed_cidrs
  allowed_mysql_cidrs = var.ssh_allowed_cidrs
  wordpress_sg_ids    = [module.wordpress.security_group_id]
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "wordpress_public_ip" {
  description = "Public IP of the WordPress instance"
  value       = module.wordpress.public_ip
}

output "db_private_ip" {
  description = "Private IP of the DB instance"
  value       = module.db.private_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for WordPress media storage"
  value       = module.s3_media.bucket_id
}

output "keypair_wordpress_name" {
  description = "Name of the WordPress SSH key pair"
  value       = module.keypair_wordpress.key_name
}

output "keypair_wordpress_path" {
  description = "Local path to the WordPress .pem file"
  value       = module.keypair_wordpress.private_key_path
}

output "keypair_db_name" {
  description = "Name of the DB SSH key pair"
  value       = module.keypair_db.key_name
}

output "keypair_db_path" {
  description = "Local path to the DB .pem file"
  value       = module.keypair_db.private_key_path
}

output "db_root_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB root password"
  value       = module.secrets.db_root_secret_arn
}

output "wp_admin_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the WordPress admin password"
  value       = module.secrets.wp_admin_secret_arn
}
