terraform {
  required_providers {
    organization_main_account = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
    audit_account = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
  }
}

locals {
  # defining this as a local allows us to reuse the same value in multiple places, 
  # without causing a cyclical dependency between aws_cloudtrail.this and aws_s3_bucket_policy.cloudtrail
  cloudtrail_name         = "org-cloudtrail"
  organization_account_id = data.aws_caller_identity.organization_account.account_id
}

data "aws_caller_identity" "organization_account" {}
data "aws_organizations_organization" "org" {}

resource "aws_cloudtrail" "this" {
  provider = organization_account

  depends_on = [aws_s3_bucket.this, aws_s3_bucket_policy.this]

  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.this.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  is_organization_trail         = true
}

resource "aws_s3_bucket" "this" {
  bucket = "cloudtrail-logs-${random_id.this.id}"

  provider = audit_account
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id = "Archive logs to lower tiers"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
    status = "Enabled"
  }

  provider = audit_account
}


resource "aws_s3_bucket_policy" "this" {
  policy = data.aws_iam_policy_document.cloudtrail.json
  bucket = aws_s3_bucket.cloudtrail.id

  provider = audit_account
}

data "aws_iam_policy_document" "this" {
  provider = audit_account

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
      values   = "arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"
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
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.organization_account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = "bucket-owner-full-control"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = "arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"
    }
  }

  statement {
    sid    = "AWSCloudTrailOrganizationWrite20150319"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = "s3:PutObject"
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_organizations_organization.org.id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = "bucket-owner-full-control"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = "arn:aws:cloudtrail:${var.region}:${local.organization_account_id}:trail/${local.cloudtrail_name}"
    }
  }
}