data "aws_caller_identity" "current" {}

# ============================================================
# Athena Execution Role
# ============================================================
resource "aws_iam_role" "athena_exec_role" {
  name               = "${var.name_prefix}-athena-exec-role"
  assume_role_policy = data.aws_iam_policy_document.athena_assume.json
  tags               = merge(var.tags, { layer = "athena" })
}

# Allow Athena and Glue service principals to assume this role
data "aws_iam_policy_document" "athena_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com", "glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# ============================================================
# Execution policy: read/write results and read Gold data + Glue catalog
# ============================================================
data "aws_iam_policy_document" "athena_exec_policy" {
  # Allow Athena to read/write query outputs
  statement {
    sid    = "S3AthenaResultsIO"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.athena_results.arn,
      "${aws_s3_bucket.athena_results.arn}/*"
    ]
  }

  # Allow Athena and Glue to read Gold data
  statement {
    sid    = "S3GoldRead"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.gold_bucket}",
      "arn:aws:s3:::${var.gold_bucket}/*"
    ]
  }

  # Allow Data Catalog access
  statement {
    sid    = "GlueCatalogRead"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables"
    ]
    resources = ["*"]
  }

  # Allow Athena APIs for query execution
  statement {
    sid    = "AthenaAPIs"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "athena_inline" {
  name   = "${var.name_prefix}-athena-inline-policy"
  role   = aws_iam_role.athena_exec_role.id
  policy = data.aws_iam_policy_document.athena_exec_policy.json
}

# ============================================================
# Outputs
# ============================================================
output "athena_execution_role_arn" {
  description = "ARN of the IAM role used by Athena"
  value       = aws_iam_role.athena_exec_role.arn
}
