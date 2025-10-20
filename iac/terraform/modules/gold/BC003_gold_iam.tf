# =============  IAM for Gold Glue Job  =========================
data "aws_iam_policy_document" "gold_glue_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gold_glue_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-glue-gold-etl-role"
  assume_role_policy = data.aws_iam_policy_document.gold_glue_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "gold_glue_inline" {
  statement {
    sid     = "ListBuckets"
    effect  = "Allow"
    actions = ["s3:GetBucketLocation","s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.silver_bucket_name}",
      aws_s3_bucket.gold.arn
    ]
  }

  # allow Glue to list the artifacts bucket so pip can locate the wheel
  statement {
    sid     = "ListArtifactsBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::bc003-artifacts-844840482726-us-east-1"]
  }


  statement {
    sid     = "ReadSilverWriteGold"
    effect  = "Allow"
    actions = [
      "s3:GetObject","s3:GetObjectVersion",
      "s3:PutObject","s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.silver_bucket_name}/*",
      "${aws_s3_bucket.gold.arn}/*"
    ]
  }

  # allow script reads from artifacts bucket
  statement {
  sid     = "ReadArtifactsScript"
  effect  = "Allow"
  actions = ["s3:GetObject","s3:GetObjectVersion"]
  resources = ["arn:aws:s3:::bc003-artifacts-844840482726-us-east-1/*"]
}

  statement {
    sid     = "GlueAndLogs"
    effect  = "Allow"
    actions = [
      "glue:*",
      "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gold_glue_inline" {
  name   = "${var.name_prefix}-gold-glue-inline"
  role   = aws_iam_role.gold_glue_role.id
  policy = data.aws_iam_policy_document.gold_glue_inline.json
}