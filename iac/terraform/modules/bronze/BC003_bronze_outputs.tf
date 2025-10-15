output "landing_bucket_name" {
  value       = aws_s3_bucket.landing.bucket
  description = "Landing bucket name"
}

output "bronze_bucket_name" {
  value       = aws_s3_bucket.bronze.bucket
  description = "Bronze bucket name"
}

# Firehose may be defined with or without count; try both simplified for single instance
output "firehose_stream_name" {
  value       = try(aws_kinesis_firehose_delivery_stream.transactions.name, null)
  description = "Firehose stream name (null if disabled/not created)"
}

output "glue_bronze_db" {
  value       = aws_glue_catalog_database.bronze.name
  description = "Glue Bronze database name"
}

# DataSync tasks may be defined with or without count; try both simplified for single instance
output "datasync_core_task_arn" {
  value       = try(aws_datasync_task.core_banking.arn, null)
  description = "DataSync core_banking task ARN (null if not created)"
}

output "datasync_loan_task_arn" {
  value       = try(aws_datasync_task.loan_mgmt.arn, null)
  description = "DataSync loan_mgmt task ARN (null if not created)"
}
