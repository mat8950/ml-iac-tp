resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.wordpress.id]
  key_name               = aws_key_pair.main.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  tags = {
    Name = local.name.wp
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.main.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  tags = {
    Name = local.name.db
  }
}
