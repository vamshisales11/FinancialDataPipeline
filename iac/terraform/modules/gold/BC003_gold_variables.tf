#Purpose: parameterize naming and region while deriving account‑specific bucket names.
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

variable "silver_bucket_name" {
  type = string
}

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  gold_bucket = "${var.name_prefix}-gold-${local.account_id}-${var.region}"
  common_tags = merge({ project = var.name_prefix, layer = "gold" }, var.tags)
}
