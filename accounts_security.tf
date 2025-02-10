# Create an account
resource "aws_organizations_account" "audit" {
  name                       = "Audit"
  email                      = "alex+audit@alexmills.uk"
  iam_user_access_to_billing = "ALLOW"

  parent_id = aws_organizations_organizational_unit.security.id
}

module "cloudtrail" {
  source = "./modules/organization_cloudtrail"

  audit_account_id = aws_organizations_account.audit.account_id
  region           = var.region
}
