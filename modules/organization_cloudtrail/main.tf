terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">=5.0.0"
      configuration_aliases = [aws.main, aws.audit]
    }
  }
}

locals {
  # defining this as a local allows us to reuse the same value in multiple places, 
  # without causing a cyclical dependency between aws_cloudtrail.this and aws_s3_bucket_policy.cloudtrail
  cloudtrail_name         = "org-cloudtrail"
  organization_account_id = data.aws_caller_identity.organization_account.id
}

data "aws_caller_identity" "organization_account" {
  provider = aws.main
}
data "aws_organizations_organization" "org" {
  provider = aws.main
}

resource "null_resource" "enable_cloudtrail_service_access" {
  provisioner "local-exec" {
    command = "aws organizations enable-aws-service-access --service-principal cloudtrail.amazonaws.com"
  }
}

resource "aws_cloudtrail" "this" {
  depends_on = [aws_s3_bucket.this, aws_s3_bucket_policy.this, null_resource.enable_cloudtrail_service_access]

  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.this.id
  include_global_service_events = true
  is_organization_trail         = true
  is_multi_region_trail         = true
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "cloudtrail-logs-"

  provider = aws.audit
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id = "Archive logs to lower tiers"

    transition {
      days          = var.log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expiry_days
    }
    status = "Enabled"
  }

  provider = aws.audit
}


resource "aws_s3_bucket_policy" "this" {
  policy = data.aws_iam_policy_document.this.json
  bucket = aws_s3_bucket.this.id

  provider = aws.audit
}

data "aws_iam_policy_document" "this" {
  provider = aws.audit

  statement {
    sid    = "AWSCloudTrailAclCheck20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/AWSLogs/${local.organization_account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailOrganizationWrite20150319"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/AWSLogs/${data.aws_organizations_organization.org.id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"]
    }
  }
}