resource "aws_athena_workgroup" "gold_analysis" {
  name        = "${var.name_prefix}-athena-gold"
  state       = "ENABLED"
  description = "Athena workgroup for querying Gold tables"
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
  tags = merge(var.tags, { project = var.name_prefix, layer = "athena" })
}

output "athena_workgroup" {
  value       = aws_athena_workgroup.gold_analysis.name
  description = "Workgroup name for Gold queries"
}