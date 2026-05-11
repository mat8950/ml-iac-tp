output "instance_id" {
  description = "ID of the DB EC2 instance"
  value       = module.instance.instance_id
}

output "private_ip" {
  description = "Private IP of the DB instance (use this in WordPress DB config)"
  value       = module.instance.private_ip
}

output "private_dns" {
  description = "Private DNS name of the DB instance"
  value       = module.instance.private_dns
}

output "security_group_id" {
  description = "ID of the DB security group"
  value       = module.sg.security_group_id
}
