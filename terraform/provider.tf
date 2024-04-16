# Terraform provider config
provider "aws" {
  region                   = var.region
  profile                  = var.profile
  shared_config_files      = var.shared_config_files
  shared_credentials_files = var.shared_credentials_files
  default_tags {
    tags = {
      ENVIRONMENT = var.ENVIRONMENT
      PROJECT     = var.PROJECT
    }
  }
}