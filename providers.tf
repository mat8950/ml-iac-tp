provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ml-iac-tp"
      Environment = "dev"
      Managed-By  = "terraform"
    }
  }
}
