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

# Add the user above to the Administrators group
resource "aws_identitystore_group_membership" "alexm_administrators" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  group_id          = aws_identitystore_group.administrators.group_id
  member_id         = aws_identitystore_user.alexm.user_id
}
