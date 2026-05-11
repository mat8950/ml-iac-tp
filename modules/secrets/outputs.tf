output "db_root_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB root password"
  value       = aws_secretsmanager_secret.db_root.arn
}

output "wp_admin_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the WordPress admin password"
  value       = aws_secretsmanager_secret.wp_admin.arn
}

output "db_root_password" {
  description = "DB root password (sensitive)"
  value       = random_password.db_root.result
  sensitive   = true
}

output "wp_admin_password" {
  description = "WordPress admin password (sensitive)"
  value       = random_password.wp_admin.result
  sensitive   = true
}
