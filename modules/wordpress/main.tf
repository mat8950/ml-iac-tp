resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  tags = {
    Name = "${var.prefix}-${var.name}-iac"
  }
}
