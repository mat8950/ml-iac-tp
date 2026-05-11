provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project     = "ml-iac-tp"
      Environment = "dev"
      Managed-By  = "terraform"
    }
  }
}
