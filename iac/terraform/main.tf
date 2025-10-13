terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
  backend "s3" {
    bucket         = "bc003-tfstate-743771860567-us-east-1"
    key            = "iac/terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bc003-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      project     = "bc003"
      environment = "single"
      owner       = "vamshi"
    }
  }
}

module "foundation" {
  source      = "./modules/foundation"
  name_prefix = "bc003"
  region      = "us-east-1"
  tags        = { owner = "vamshi" }

  enable_cmk                 = false
  enable_kms_data_use_policy = false
  create_kms_alias           = false
}
