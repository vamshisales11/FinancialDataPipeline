#Declares provider configuration and allows alias aws.notags for the role.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
      configuration_aliases = [ aws.notags ]
    }
  }
}