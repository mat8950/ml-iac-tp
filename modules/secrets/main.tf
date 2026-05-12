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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "db_root" {
  secret_id     = aws_secretsmanager_secret.db_root.id
  secret_string = random_password.db_root.result
}

resource "aws_secretsmanager_secret" "ssh_key_db" {
  name                    = "${var.prefix}/ssh/db"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.prefix}-secret-ssh-db-iac"
  }
}

resource "aws_secretsmanager_secret_version" "ssh_key_db" {
  secret_id     = aws_secretsmanager_secret.ssh_key_db.id
  secret_string = var.ssh_key_db
}
