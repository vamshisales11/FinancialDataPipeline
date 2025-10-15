variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}
variable "enable_datasync" {
  type        = bool
  default     = false
  description = "Enable the DataSync module"
}

variable "enable_firehose" {
  type        = bool
  default     = false
  description = "Enable the Firehose module"
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_caller_identity" "current" {}

locals {
  account_id     = data.aws_caller_identity.current.account_id
  landing_bucket = "${var.name_prefix}-landing-${local.account_id}-${var.region}"
  bronze_bucket  = "${var.name_prefix}-bronze-${local.account_id}-${var.region}"
  firehose_name  = "${var.name_prefix}-firehose-transactions"
  common_tags    = merge({ project = var.name_prefix, layer = "bronze" }, var.tags)
}