provider "aws" {
  region  = var.region
}

resource "aws_organizations_account" "production" {
  name                       = "Production"
  email                      = "alex+production@alexmills.uk"
  iam_user_access_to_billing = "ALLOW"

  tags = {
    Name  = "Production"
    Owner = "AlexMills-UK"
    Role  = "production"
  }

  parent_id = aws_organizations_organizational_unit.workloads_production.id
}

provider "aws" {
  alias  = "production"
  region = "eu-west-2"

  default_tags {
    tags = {
      Repository = "github.com/alexmills-uk/aws-organisation"
      Owner      = "platform-team"
      Terraform  = "true"
    }
  }

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.production.id}:role/OrganizationAccountAccessRole"
  }

  allowed_account_ids = [
    aws_organizations_account.production.id
  ]
}

module "production_terraform_state" {
  source = "./modules/terraform_state"
  providers = {
    aws = aws.production
  }
  depends_on = [ aws_organizations_account.production ]
}