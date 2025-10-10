terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
  backend "s3" {
    bucket         = "bc003-tfstate-743771860567-us-east-1"  # replace with your $TF_BUCKET
    key            = "iac/terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bc003-tfstate-lock"
    encrypt        = true
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