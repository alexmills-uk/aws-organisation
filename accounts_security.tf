# Create an account
resource "aws_organizations_account" "audit" {
  name                       = "Audit"
  email                      = "alex+audit@alexmills.uk"
  iam_user_access_to_billing = "ALLOW"

  parent_id = aws_organizations_organizational_unit.security.id
}

# Assume the OrganizationAccountAccessRole to jump into the sub-account, and create resources.
provider "aws" {
  alias  = "audit"
  region = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.audit.id}:role/OrganizationAccountAccessRole"
  }

  allowed_account_ids = [
    aws_organizations_account.audit.id
  ]
}


module "cloudtrail" {
  source = "./modules/organization_cloudtrail"

  region = var.region

  providers = {
    aws.main  = aws
    aws.audit = aws.audit
  }

  depends_on = [aws_organizations_account.audit]
}
