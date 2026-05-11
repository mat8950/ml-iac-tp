resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = local.name.keypair
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = local.name.keypair
  }
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${local.name.keypair}.pem"
  file_permission = "0600"
}
