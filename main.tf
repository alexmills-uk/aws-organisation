provider "aws" {
  region  = var.region
}

data "aws_ssoadmin_instances" "this" {}

resource "aws_identitystore_group" "administrators" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  display_name      = "Administrators"
  description       = "Administrators of the AWS Organisation"
}

resource "aws_identitystore_user" "alexm" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0] 

  display_name = "Alex Mills"
  user_name    = "alexm"

  name {
    given_name  = "Alex"
    family_name = "Mills"
  }

  emails {
    value = "alex+user@alexmills.uk"
  }
}

resource "aws_identitystore_group_membership" "alexm_administrators" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  group_id          = aws_identitystore_group.administrators.group_id
  member_id         = aws_identitystore_user.alexm.user_id
}

resource "aws_ssoadmin_permission_set" "admin_permissionset" {
  name         = "admin-permissionset"
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_managed_policy_attachment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin_permissionset.arn
}

data "aws_organizations_organization" "org" {}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "suspended" {
  name      = "Suspended"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
 parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "exceptions" {
  name      = "Exceptions"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_dev" {
  name      = "Development"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_staging" {
  name      = "Staging"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads_production" {
  name      = "Production"
  parent_id = data.aws_organizations_organization.org.roots[0].id
}