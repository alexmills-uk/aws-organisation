resource "aws_ssoadmin_permission_set" "admin_permissionset" {
  name         = "AdministratorAccess"
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator_managed_policy_attachment" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin_permissionset.arn
}