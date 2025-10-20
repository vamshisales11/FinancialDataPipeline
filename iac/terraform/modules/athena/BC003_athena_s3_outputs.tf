resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.name_prefix}-athena-results-${var.region}"
  tags   = merge(var.tags, { project = var.name_prefix, service = "athena" })
}

resource "aws_s3_bucket_public_access_block" "results_block" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "results_enc" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

output "athena_results_bucket" {
  value       = aws_s3_bucket.athena_results.bucket
  description = "S3 bucket where Athena stores query outputs"
}
