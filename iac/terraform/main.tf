terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
  backend "s3" {
    bucket         = "bc003-tfstate-844840482726-us-east-1"
    key            = "iac/terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bc003-tfstate-lock"
    encrypt        = true
  }
}

# Default provider (with default_tags for everything except IAM roles)
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

provider "aws" {
  alias  = "notags"
  region = "us-east-1"
}

module "bronze" {
  source      = "./modules/bronze"
  name_prefix = "bc003"
  region      = "us-east-1"
  tags        = { owner = "vamshi" }

  providers = {
    aws        = aws
    aws.notags = aws.notags
  }
  enable_datasync = true
  enable_firehose = false # set to true later when Firehose is fully enabled and PassRole allowed
}


module "silver" {
  source             = "./modules/silver"
  name_prefix        = "bc003"
  region             = "us-east-1"
  tags               = { owner = "vamshi" }
  bronze_bucket_name = module.bronze.bronze_bucket_name
  providers = {
    aws        = aws
    aws.notags = aws.notags
  }
}