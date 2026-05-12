# ── Locals ───────────────────────────────────────────────────────────────────

locals {
  prefix = var.prefix

  name = {
    vpc        = "${local.prefix}-vpc-iac"
    igw        = "${local.prefix}-igw-iac"
    sg_db      = "${local.prefix}-sg-db-iac"
    keypair_db = "${local.prefix}-keypair-db-iac"
    db         = "${local.prefix}-db-iac"
  }

  # First site key (alphabetical) — used as SSH bastion to reach the DB
  bastion_site_key = tolist(keys(var.sites))[0]
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

  name               = local.prefix
  vpc_cidr           = "10.0.0.0/16"
  enable_nat_gateway = var.enable_nat_gateway
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

# Clé SSH par site WordPress
module "keypair_wp" {
  for_each = var.sites
  source   = "./modules/keypair"

  name                    = "${local.prefix}-keypair-${each.key}-iac"
  private_key_output_path = "/tmp/wp_keys_${local.prefix}"
}

# Clé SSH pour la DB (partagée)
module "keypair_db" {
  source = "./modules/keypair"

  name                    = local.name.keypair_db
  private_key_output_path = "/tmp/wp_keys_${local.prefix}"
}

# Secrets DB (root password + clé SSH DB)
module "secrets" {
  source = "./modules/secrets"

  prefix     = local.prefix
  ssh_key_db = module.keypair_db.private_key_pem
}

# Mot de passe DB applicatif par site
resource "random_password" "wp_db" {
  for_each         = var.sites
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "wp_db_password" {
  for_each                = var.sites
  name                    = "${local.prefix}/site/${each.key}/db-password"
  recovery_window_in_days = 0
  tags                    = { Name = "${local.prefix}-secret-db-${each.key}-iac" }
}

resource "aws_secretsmanager_secret_version" "wp_db_password" {
  for_each      = var.sites
  secret_id     = aws_secretsmanager_secret.wp_db_password[each.key].id
  secret_string = random_password.wp_db[each.key].result
}

# Mot de passe admin WordPress par site
resource "random_password" "wp_admin" {
  for_each         = var.sites
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "wp_admin_password" {
  for_each                = var.sites
  name                    = "${local.prefix}/site/${each.key}/admin-password"
  recovery_window_in_days = 0
  tags                    = { Name = "${local.prefix}-secret-wp-admin-${each.key}-iac" }
}

resource "aws_secretsmanager_secret_version" "wp_admin_password" {
  for_each      = var.sites
  secret_id     = aws_secretsmanager_secret.wp_admin_password[each.key].id
  secret_string = random_password.wp_admin[each.key].result
}

# Clé SSH WordPress par site dans Secrets Manager
resource "aws_secretsmanager_secret" "wp_ssh_key" {
  for_each                = var.sites
  name                    = "${local.prefix}/ssh/${each.key}"
  recovery_window_in_days = 0
  tags                    = { Name = "${local.prefix}-secret-ssh-${each.key}-iac" }
}

resource "aws_secretsmanager_secret_version" "wp_ssh_key" {
  for_each      = var.sites
  secret_id     = aws_secretsmanager_secret.wp_ssh_key[each.key].id
  secret_string = module.keypair_wp[each.key].private_key_pem
}

# ── IAM : accès S3 pour les instances WordPress ───────────────────────────────

resource "aws_iam_role" "wp_s3" {
  name = "${local.prefix}-wp-s3-role-iac"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "wp_s3" {
  name = "${local.prefix}-wp-s3-policy-iac"
  role = aws_iam_role.wp_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketOwnershipControls",
        "s3:GetBucketAcl"
      ]
      Resource = [
        module.s3_media.bucket_arn,
        "${module.s3_media.bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "wp_s3" {
  name = "${local.prefix}-wp-s3-profile-iac"
  role = aws_iam_role.wp_s3.name
}

# ── Couche 3 : Application (une instance par site) ───────────────────────────

module "wordpress" {
  for_each = var.sites
  source   = "./modules/wordpress"

  name                 = "${local.prefix}-wp-${each.key}-iac"
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.public_subnet_ids[0]
  ami_id               = data.aws_ami.al2023.id
  key_name             = module.keypair_wp[each.key].key_name
  allowed_ssh_cidrs    = var.ssh_allowed_cidrs
  iam_instance_profile = aws_iam_instance_profile.wp_s3.name
}

# ── Couche 4 : Données ────────────────────────────────────────────────────────

module "db" {
  source = "./modules/database"

  name                = local.name.db
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.private_subnet_ids[0]
  ami_id              = data.aws_ami.al2023.id
  key_name            = module.keypair_db.key_name
  mysql_port          = 5432
  allowed_ssh_cidrs   = var.ssh_allowed_cidrs
  allowed_mysql_cidrs = var.ssh_allowed_cidrs
  wordpress_sg_ids    = [for k, v in module.wordpress : v.security_group_id]
}

# ── Inventaire Ansible (généré automatiquement) ───────────────────────────────

resource "local_sensitive_file" "ansible_inventory" {
  filename        = "${path.module}/ansible/inventory/hosts.yml"
  file_permission = "0640"

  content = templatefile("${path.module}/ansible/inventory/hosts.yml.tftpl", {
    sites = {
      for site_key, site_cfg in var.sites : site_key => {
        public_ip      = module.wordpress[site_key].public_ip
        site_title     = site_cfg.site_title
        admin_user     = site_cfg.admin_user
        admin_email    = site_cfg.admin_email
        db_password    = random_password.wp_db[site_key].result
        admin_password = random_password.wp_admin[site_key].result
      }
    }
    keys_dir         = "/tmp/wp_keys_${local.prefix}"
    prefix           = local.prefix
    aws_region       = var.aws_region
    s3_bucket        = module.s3_media.bucket_id
    db_private_ip    = module.db.private_ip
    bastion_ip       = module.wordpress[local.bastion_site_key].public_ip
    bastion_key_path = "/tmp/wp_keys_${local.prefix}/${local.prefix}-keypair-${local.bastion_site_key}-iac.pem"
    keypair_db_name  = local.name.keypair_db
  })
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "wordpress_public_ips" {
  description = "Public IPs of the WordPress instances"
  value       = { for k, v in module.wordpress : k => v.public_ip }
}

output "db_private_ip" {
  description = "Private IP of the DB instance"
  value       = module.db.private_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for WordPress media storage"
  value       = module.s3_media.bucket_id
}

output "keypair_db_path" {
  description = "Local path to the DB .pem file"
  value       = module.keypair_db.private_key_path
}

output "db_root_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB root password"
  value       = module.secrets.db_root_secret_arn
}
