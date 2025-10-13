output "kms_key_arn" {
  description = "CMK ARN (null if CMK disabled)"
  value       = var.enable_cmk ? aws_kms_key.data[0].arn : null
}

output "kms_alias_arn" {
  description = "Alias ARN (null if alias disabled)"
  value       = var.enable_cmk && var.create_kms_alias ? aws_kms_alias.data_alias[0].arn : null
}

output "kms_data_use_policy_arn" {
  description = "KMS usage policy ARN (null if disabled)"
  value       = var.enable_kms_data_use_policy ? aws_iam_policy.kms_data_use[0].arn : null
}