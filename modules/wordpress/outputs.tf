output "instance_id" {
  description = "ID of the WordPress EC2 instance"
  value       = module.instance.instance_id
}

output "public_ip" {
  description = "Public IP of the WordPress instance"
  value       = module.instance.public_ip
}

output "private_ip" {
  description = "Private IP of the WordPress instance"
  value       = module.instance.private_ip
}

output "public_dns" {
  description = "Public DNS of the WordPress instance"
  value       = module.instance.public_dns
}

output "security_group_id" {
  description = "ID of the WordPress security group (used by the DB module)"
  value       = module.sg.security_group_id
}
