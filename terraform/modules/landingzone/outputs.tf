output "organization_id" {
  value = aws_organizations_organization.this.id
}
output "organizational_units" {
  value = {
    security  = aws_organizations_organizational_unit.security.id
    workloads = aws_organizations_organizational_unit.workloads.id
    sandbox   = aws_organizations_organizational_unit.sandbox.id
  }
}
output "cloudtrail_bucket" {
  value = aws_s3_bucket.logs.id
}
