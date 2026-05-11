resource "random_id" "s3_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "wordpress_media" {
  bucket = "${local.prefix}-s3-iac-${random_id.s3_suffix.hex}"

  tags = {
    Name = "${local.prefix}-s3-iac"
  }
}

resource "aws_s3_bucket_public_access_block" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
