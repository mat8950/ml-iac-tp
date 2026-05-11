output "wordpress_public_ip" {
  description = "Public IP of the WordPress instance — use this to access the site"
  value       = module.wordpress.public_ip
}

output "db_private_ip" {
  description = "Private IP of the DB instance — use this in WordPress DB config"
  value       = aws_instance.db.private_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for WordPress media storage"
  value       = aws_s3_bucket.wordpress_media.bucket
}

output "keypair_name" {
  description = "Name of the SSH key pair — use with mathis-keypair-iac.pem"
  value       = aws_key_pair.main.key_name
}

output "db_root_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB root password"
  value       = aws_secretsmanager_secret.db_root.arn
}

output "wp_admin_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the WordPress admin password"
  value       = aws_secretsmanager_secret.wp_admin.arn
}
