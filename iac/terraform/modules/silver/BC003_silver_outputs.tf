output "silver_bucket_name" { value = aws_s3_bucket.silver.bucket }
output "artifacts_bucket_name" { value = aws_s3_bucket.artifacts.bucket }
output "glue_silver_db" { value = aws_glue_catalog_database.silver.name }
output "glue_job_role_arn" { value = aws_iam_role.glue_etl_role.arn }