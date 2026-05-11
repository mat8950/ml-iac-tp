resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = var.rsa_bits
}

resource "aws_key_pair" "this" {
  key_name   = var.name
  public_key = tls_private_key.this.public_key_openssh

  tags = merge({ Name = var.name }, var.tags)
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${var.private_key_output_path}/${var.name}.pem"
  file_permission = "0600"
}
