data "aws_caller_identity" "current" {}

resource "aws_organizations_organization" "this" {
  feature_set                   = "ALL"
  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.this.roots[0].id
}

############################
# Guardrail SCPs
############################
resource "aws_organizations_policy" "guardrails" {
  name        = "${var.name_prefix}-guardrails"
  description = "Protect the org and CloudTrail"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = ["organizations:LeaveOrganization"]
        Resource = "*"
      },
      {
        Sid      = "ProtectCloudTrail"
        Effect   = "Deny"
        Action   = ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy" "region_lock" {
  name        = "${var.name_prefix}-region-lock"
  description = "Restrict resource creation to approved regions"
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "RegionLock"
      Effect = "Deny"
      NotAction = [
        "iam:*", "organizations:*", "route53:*", "cloudfront:*",
        "sts:*", "support:*", "globalaccelerator:*", "budgets:*", "waf:*",
      ]
      Resource  = "*"
      Condition = { StringNotEquals = { "aws:RequestedRegion" = var.allowed_regions } }
    }]
  })
}

resource "aws_organizations_policy_attachment" "guardrails" {
  policy_id = aws_organizations_policy.guardrails.id
  target_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_policy_attachment" "region_lock" {
  policy_id = aws_organizations_policy.region_lock.id
  target_id = aws_organizations_organization.this.roots[0].id
}

############################
# Centralized CloudTrail
############################
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name_prefix}-org-trail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/AWSLogs/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

resource "aws_cloudtrail" "org" {
  name                          = "${var.name_prefix}-org-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  is_organization_trail         = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  depends_on                    = [aws_s3_bucket_policy.logs, aws_organizations_organization.this]
}
