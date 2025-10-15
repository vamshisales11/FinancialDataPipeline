resource "aws_s3_bucket" "landing" {
  bucket = local.landing_bucket
  tags   = merge(local.common_tags, { bucket = "landing" })
}

resource "aws_s3_bucket" "bronze" {
  bucket = local.bronze_bucket
  tags   = merge(local.common_tags, { bucket = "bronze" })
}

resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Default SSE-KMS using AWS-managed key (alias/aws/s3)
resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "landing" {
  bucket                  = aws_s3_bucket.landing.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bronze" {
  bucket                  = aws_s3_bucket.bronze.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id
  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    # Apply rule to all objects in the bucket
    filter {
      prefix = ""
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bronze" {
  bucket = aws_s3_bucket.bronze.id
  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    # Apply rule to all objects in the bucket
    filter {
      prefix = ""
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_policy" "landing_tls_only" {
  bucket = aws_s3_bucket.landing.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "DenyInsecureTransport",
      Effect    = "Deny",
      Principal = "*",
      Action    = "s3:*",
      Resource = [
        aws_s3_bucket.landing.arn,
        "${aws_s3_bucket.landing.arn}/*"
      ],
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_policy" "bronze_tls_only" {
  bucket = aws_s3_bucket.bronze.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "DenyInsecureTransport",
      Effect    = "Deny",
      Principal = "*",
      Action    = "s3:*",
      Resource = [
        aws_s3_bucket.bronze.arn,
        "${aws_s3_bucket.bronze.arn}/*"
      ],
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}