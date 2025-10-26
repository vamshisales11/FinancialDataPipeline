variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "artifacts_bucket_name" {
  type = string  # Example: bc003-artifacts-844840482726-us-east-1
}

variable "interactions_prefix" {
  type    = string
  default = "personalize/interactions/"  # Must end with /
}

variable "batch_input_prefix" {
  type    = string
  default = "personalize/batch/input/"   # Must end with /
}

variable "batch_output_prefix" {
  type    = string
  default = "personalize/batch/output/"  # Must end with /
}

variable "enable_batch_inference" {
  type    = bool
  default = true
}

variable "batch_num_results" {
  type    = number
  default = 10
}

variable "dataset_group_name" {
  type    = string
  default = null
}

variable "solution_name" {
  type    = string
  default = null
}

variable "personalize_role_name" {
  type    = string
  default = "bc003-personalize-role"
}

variable "recipe_arn" {
  type    = string
  default = "arn:aws:personalize:::recipe/aws-user-personalization"
}

# Retrieve current AWS account information
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Default Names
  dataset_group_name = coalesce(var.dataset_group_name, "${var.name_prefix}-banking")
  solution_name      = coalesce(var.solution_name, "${var.name_prefix}-banking-solution")

  # S3 Paths
  interactions_path = "s3://${var.artifacts_bucket_name}/${var.interactions_prefix}"
  batch_input_path  = "s3://${var.artifacts_bucket_name}/${var.batch_input_prefix}"
  batch_output_path = "s3://${var.artifacts_bucket_name}/${var.batch_output_prefix}"
}
