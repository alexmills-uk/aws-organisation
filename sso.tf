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
  name         = "AdministratorAccess"
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_managed_policy_attachment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin_permissionset.arn
}

resource "aws_ssoadmin_account_assignment" "admin_role_assignment" {
  for_each = { for account in data.aws_organizations_organization.org.accounts : account.id => account }

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  principal_id       = aws_identitystore_group.administrators.group_id
  principal_type     = "GROUP"
  target_type        = "AWS_ACCOUNT"
  target_id          = each.key
  permission_set_arn = aws_ssoadmin_permission_set.admin_permissionset.arn
}