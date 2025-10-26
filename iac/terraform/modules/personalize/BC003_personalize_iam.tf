# IAM Trust Policy for Amazon Personalize
data "aws_iam_policy_document" "p13_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["personalize.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Role for Amazon Personalize
resource "aws_iam_role" "personalize_role" {
  provider           = aws.notags
  name               = var.personalize_role_name
  assume_role_policy = data.aws_iam_policy_document.p13_trust.json
}

# IAM S3 Access Policy for Personalize
data "aws_iam_policy_document" "p13_s3_access" {
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.artifacts_bucket_name}"]
  }

  statement {
    sid       = "ReadInputs"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.artifacts_bucket_name}/${var.interactions_prefix}*",
      "arn:aws:s3:::${var.artifacts_bucket_name}/${var.batch_input_prefix}*"
    ]
  }

  statement {
    sid       = "WriteOutputs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${var.artifacts_bucket_name}/${var.batch_output_prefix}*"
    ]
  }
}

# Inline IAM Policy Attachment
resource "aws_iam_role_policy" "p13_inline" {
  name   = "${var.name_prefix}-personalize-s3"
  role   = aws_iam_role.personalize_role.id
  policy = data.aws_iam_policy_document.p13_s3_access.json
}
