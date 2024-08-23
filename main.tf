locals {
  tags = {
      Repository = "github.com/alexmills-uk/aws-organisation"
      Owner = "AlexMills-UK"
      Role  = "production"
      Terraform  = "true"
    }
}
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}