variable "aws_region" {
  description = "Home region for the organization trail"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "ahmad-landingzone"
}
