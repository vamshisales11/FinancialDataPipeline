terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
      # Tell Terraform this module expects the aws.notags alias from the root
      configuration_aliases = [
        aws.notags
      ]
    }
  }
}