variable "name_prefix" {
  description = "Project prefix (e.g., bc003)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "enable_cmk" {
  description = "Create a customer-managed KMS key (CMK). If false, skip CMK."
  type        = bool
  default     = false
}

variable "enable_kms_data_use_policy" {
  description = "Create reusable IAM policy for KMS usage"
  type        = bool
  default     = false
}

variable "create_kms_alias" {
  description = "Create alias for the CMK"
  type        = bool
  default     = false
}