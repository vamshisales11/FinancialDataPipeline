data "aws_iam_policy_document" "glue_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_etl_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-glue-etl-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

data "aws_iam_policy_document" "glue_etl_inline" {
  # List buckets / get location
  statement {
    effect  = "Allow"
    actions = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.bronze_bucket_name}",
      aws_s3_bucket.silver.arn,
      aws_s3_bucket.artifacts.arn,

    ]
  }

  # Read Bronze
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${var.bronze_bucket_name}/*", "${aws_s3_bucket.artifacts.arn}/*"]
  }

  # Write Silver / Artifacts
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload"]
    resources = [
      "${aws_s3_bucket.silver.arn}/*",
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
  }

  # Glue + Logs
  statement {
    effect = "Allow"
    actions = [
      "glue:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "glue_etl_inline" {
  name   = "${var.name_prefix}-glue-etl-inline"
  role   = aws_iam_role.glue_etl_role.id
  policy = data.aws_iam_policy_document.glue_etl_inline.json
}
