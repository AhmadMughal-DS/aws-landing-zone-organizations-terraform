variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ahmad-landingzone"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric/hyphens, 2-31 chars."
  }
}

variable "environment" {
  type    = string
  default = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "allowed_regions" {
  description = "Regions resources may be created in (region-lock SCP)"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}
