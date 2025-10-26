output "personalize_role_arn" {
  description = "ARN of the AWS IAM role used by Amazon Personalize."
  value       = aws_iam_role.personalize_role.arn
}

output "dataset_group_arn" {
  description = "ARN of the Amazon Personalize dataset group."
  value       = aws_personalize_dataset_group.this.arn
}

output "interactions_dataset_arn" {
  description = "ARN of the Amazon Personalize interactions dataset."
  value       = aws_personalize_dataset.interactions.arn
}

output "import_job_arn" {
  description = "ARN of the Amazon Personalize dataset import job."
  value       = aws_personalize_dataset_import_job.interactions.arn
}

output "solution_arn" {
  description = "ARN of the Amazon Personalize solution."
  value       = aws_personalize_solution.this.arn
}

output "solution_version_arn" {
  description = "ARN of the Amazon Personalize solution version."
  value       = aws_personalize_solution_version.v1.arn
}

output "batch_job_arn" {
  description = "ARN of the Amazon Personalize batch inference job (if enabled)."
  value       = try(aws_personalize_batch_inference_job.batch[0].arn, null)
}

output "interactions_s3_path" {
  description = "S3 path containing interactions data."
  value       = local.interactions_path
}

output "batch_input_s3_path" {
  description = "S3 path for batch input data."
  value       = local.batch_input_path
}

output "batch_output_s3_path" {
  description = "S3 path for batch output results."
  value       = local.batch_output_path
}
