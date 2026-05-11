resource "random_password" "db_root" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]<>?"
}

resource "aws_secretsmanager_secret" "db_root" {
  name                    = "${var.prefix}/db/root-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.prefix}-secret-db-root-iac"
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
  name                    = "${var.prefix}/wordpress/admin-password"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.prefix}-secret-wp-admin-iac"
  }
}

resource "aws_secretsmanager_secret_version" "wp_admin" {
  secret_id     = aws_secretsmanager_secret.wp_admin.id
  secret_string = random_password.wp_admin.result
}

resource "aws_secretsmanager_secret" "ssh_key" {
  for_each = var.ssh_keys

  name                    = "${var.prefix}/ssh/${each.key}"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.prefix}-secret-ssh-${each.key}-iac"
  }
}

resource "aws_secretsmanager_secret_version" "ssh_key" {
  for_each = var.ssh_keys

  secret_id     = aws_secretsmanager_secret.ssh_key[each.key].id
  secret_string = each.value
}
