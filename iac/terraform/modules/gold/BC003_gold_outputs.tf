

output "gold_bucket_name" {
  description = "Name of the Gold S3 bucket"
  value       = aws_s3_bucket.gold.bucket
}

output "glue_gold_db" {
  description = "Name of the Glue Catalog database for the Gold layer"
  value       = aws_glue_catalog_database.gold.name
}

output "glue_gold_role_arn" {
  description = "ARN of the IAM role assumed by Glue for Gold ETL"
  value       = aws_iam_role.gold_glue_role.arn
}
