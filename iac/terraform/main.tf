terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Modules will be added later in order:
# module "foundation" {}
# module "bronze" {}
# module "silver" {}
# module "gold" {}
# module "athena" {}
# module "redshift" {}
# module "monitoring" {}