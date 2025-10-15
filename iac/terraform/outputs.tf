# Outputs will be added as modules are implemented.
# Examples to come: bucket_arns, kms_key_arn, role_arns, stream_names, etc.


# Map Bronze module outputs to root outputs so `terraform output` works

output "landing_bucket_name" {
  description = "Landing bucket name"
  value       = try(module.bronze.landing_bucket_name, null)
}

output "bronze_bucket_name" {
  description = "Bronze bucket name"
  value       = try(module.bronze.bronze_bucket_name, null)
}

output "datasync_core_task_arn" {
  description = "DataSync task ARN for core_banking"
  value       = try(module.bronze.datasync_core_task_arn, null)
}

output "datasync_loan_task_arn" {
  description = "DataSync task ARN for loan_mgmt"
  value       = try(module.bronze.datasync_loan_task_arn, null)
}

output "silver_bucket_name" {
  value = module.silver.silver_bucket_name
}

output "artifacts_bucket_name" {
  value = module.silver.artifacts_bucket_name
}

output "glue_silver_db" {
  value = module.silver.glue_silver_db
}

output "glue_job_role_arn" {
  value = module.silver.glue_job_role_arn
}
