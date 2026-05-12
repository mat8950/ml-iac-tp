output "db_root_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB root password"
  value       = aws_secretsmanager_secret.db_root.arn
}

output "db_root_password" {
  description = "DB root password (sensitive)"
  value       = random_password.db_root.result
  sensitive   = true
}

output "ssh_key_db_arn" {
  description = "Secrets Manager ARN for the DB SSH private key"
  value       = aws_secretsmanager_secret.ssh_key_db.arn
}
