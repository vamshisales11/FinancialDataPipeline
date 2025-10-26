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


module "gold" {
  source             = "./modules/gold"
  name_prefix        = "bc003"
  region             = "us-east-1"
  tags               = { owner = "vamshi" }
  silver_bucket_name = module.silver.silver_bucket_name

  providers = {
    aws        = aws
    aws.notags = aws.notags
  }
}

module "athena" {
  source      = "./modules/athena"
  name_prefix = "bc003"
  region      = "us-east-1"
  gold_bucket = module.gold.gold_bucket_name
  tags        = { owner = "vamshi" }

  providers = {
    aws = aws
  }
}


module "monitoring" {
  source      = "./modules/monitoring"
  name_prefix = "bc003"
  region      = "us-east-1"
  tags        = { owner = "vamshi" }

  providers = {
    aws        = aws
    aws.notags = aws.notags
  }

  glue_job_names = [
    #"bc003-bronze-to-silver", removed job name filter
    #"bc003-silver-to-gold"
  ]

  datasync_task_arns = [
    for arn in [
      module.bronze.datasync_core_task_arn,
      module.bronze.datasync_loan_task_arn
    ] : arn if arn != null
  ]

  # Deploy now without SNS permissions
  enable_alerts    = false
  create_sns_topic = false

  # Later, when permitted:
  # enable_alerts    = true
  # create_sns_topic = true                    # or keep false and provide sns_topic_arn = "arn:aws:sns:..."
  # alert_emails     = ["you@example.com"]
}



module "ml" {
  source                = "./modules/ml"
  name_prefix           = "bc003"
  region                = "us-east-1"
  artifacts_bucket_name = module.silver.artifacts_bucket_name

  providers = {
    aws        = aws
    aws.notags = aws.notags
  }

  # Start simple: create Lambda + EventBridge only
   lambda_zip_path = abspath("${path.root}/../../tools/ml_lambda/ml_alert.zip")
   threshold       = 0.9
  # sns_topic_arn = "arn:aws:sns:us-east-1:844840482726:existing-topic"  # optional

  # Enable these in sequence once features are in place
  enable_training        = false
  enable_model           = false
  enable_batch_transform = false

  run_id = "v1" # bump to re-run transform via TF
}



