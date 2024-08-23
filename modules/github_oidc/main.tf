terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        for repository in var.allowed_repositories : "repo:${repository}"
      ]
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  name               = "github-deployment"
  path               = "/github-oidc/"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

# Ideally, this the policy attached should be more tightly scoped as AdministratorAccess is quite a wide permission set.
# Alternatively, use SCPs to limit the scope of AdministratorAccess.
resource "aws_iam_role_policy_attachment" "github_oidc_role_policy" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
