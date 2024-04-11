# Terraform provider config
provider "aws" {
  alias   = "default"
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      ENVIRONMENT = var.ENVIRONMENT
      PROJECT     = var.PROJECT
    }
  }
}