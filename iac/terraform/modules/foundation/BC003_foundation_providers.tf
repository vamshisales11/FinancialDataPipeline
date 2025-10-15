terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

# Declare the alias used inside this module so Terraform knows about aws.notags
# Config (region, etc.) comes from the root module mapping
provider "aws" {
  alias = "notags"
}