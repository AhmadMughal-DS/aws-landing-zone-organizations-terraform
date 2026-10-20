output "organization_id" {
  description = "AWS Organizations ID"
  value       = aws_organizations_organization.this.id
}

output "organizational_units" {
  description = "Created OU IDs"
  value = {
    security  = aws_organizations_organizational_unit.security.id
    workloads = aws_organizations_organizational_unit.workloads.id
    sandbox   = aws_organizations_organizational_unit.sandbox.id
  }
}

output "cloudtrail_bucket" {
  description = "Centralized CloudTrail log bucket"
  value       = aws_s3_bucket.logs.id
}
