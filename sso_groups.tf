resource "aws_identitystore_group" "administrators" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  display_name      = "Administrators"
  description       = "Administrators of the AWS Organisation"
}

# Assign the Administrators group to every account
resource "aws_ssoadmin_account_assignment" "admin_role_assignment" {
  for_each = { for account in data.aws_organizations_organization.org.accounts : account.id => account }

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  principal_id       = aws_identitystore_group.administrators.group_id
  principal_type     = "GROUP"
  target_type        = "AWS_ACCOUNT"
  target_id          = each.key
  permission_set_arn = aws_ssoadmin_permission_set.admin_permissionset.arn
}