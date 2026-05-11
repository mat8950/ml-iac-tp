resource "random_password" "db_root" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "db_root" {
  name                    = "${local.prefix}/db/root-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.prefix}-secret-db-root-iac"
  }
}

resource "aws_secretsmanager_secret_version" "db_root" {
  secret_id     = aws_secretsmanager_secret.db_root.id
  secret_string = random_password.db_root.result
}

resource "random_password" "wp_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "wp_admin" {
  name                    = "${local.prefix}/wordpress/admin-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.prefix}-secret-wp-admin-iac"
  }
}

resource "aws_secretsmanager_secret_version" "wp_admin" {
  secret_id     = aws_secretsmanager_secret.wp_admin.id
  secret_string = random_password.wp_admin.result
}
