locals {
  name_prefix = var.project_name
}

module "landingzone" {
  source          = "./modules/landingzone"
  name_prefix     = local.name_prefix
  environment     = var.environment
  allowed_regions = var.allowed_regions
}
