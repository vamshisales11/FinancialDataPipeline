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

variable "bronze_bucket_name" {
  type = string
}

data "aws_caller_identity" "current" {}

locals {
  account_id       = data.aws_caller_identity.current.account_id
  silver_bucket    = "${var.name_prefix}-silver-${local.account_id}-${var.region}"
  artifacts_bucket = "${var.name_prefix}-artifacts-${local.account_id}-${var.region}"
  common_tags      = merge({ project = var.name_prefix, layer = "silver" }, var.tags)
}