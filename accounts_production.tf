# Create an account
resource "aws_organizations_account" "production" {
  name                       = "Production"
  email                      = "alex+production@alexmills.uk"
  iam_user_access_to_billing = "ALLOW"

  parent_id = aws_organizations_organizational_unit.workloads_production.id
}

# Assume the OrganizationAccountAccessRole to jump into the sub-account, and create resources.
provider "aws" {
  alias  = "production"
  region = "eu-west-2"

  default_tags {
    tags = local.tags
  }

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.production.id}:role/OrganizationAccountAccessRole"
  }

  allowed_account_ids = [
    aws_organizations_account.production.id
  ]
}

# Create an S3 bucket and DynamoDB table to allow for Terraform State Locking
module "production_terraform_state" {
  source = "./modules/terraform_state"
  providers = {
    aws = aws.production
  }
  depends_on = [aws_organizations_account.production]
}

# Create an OIDC provider to allow GitHub actions to assume an appropriate role
module "production_github_oidc" {
  source = "./modules/github_oidc"
  allowed_repositories = ["alexmills-uk/*:*"]
  providers = {
    aws = aws.production
  }
  depends_on = [aws_organizations_account.production]
}
