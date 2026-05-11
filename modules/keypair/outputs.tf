output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.this.key_name
}

output "key_pair_id" {
  description = "ID of the AWS key pair"
  value       = aws_key_pair.this.id
}

output "public_key" {
  description = "Public key in OpenSSH format"
  value       = tls_private_key.this.public_key_openssh
}

output "private_key_path" {
  description = "Local path to the saved private key file"
  value       = local_sensitive_file.private_key.filename
}

output "private_key_pem" {
  description = "Private key in PEM format (sensitive)"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}
