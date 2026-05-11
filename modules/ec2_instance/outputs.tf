output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address of the instance (null if no public IP)"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.this.public_dns
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.this.private_dns
}

output "arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}
