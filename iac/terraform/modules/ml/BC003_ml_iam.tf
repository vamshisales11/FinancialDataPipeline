# SageMaker Execution Role
data "aws_iam_policy_document" "sm_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sm_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-sagemaker-exec-role"
  assume_role_policy = data.aws_iam_policy_document.sm_assume.json
}

data "aws_iam_policy_document" "sm_inline" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.artifacts_bucket_name}",
      "arn:aws:s3:::${var.artifacts_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.artifacts_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sm_inline" {
  name   = "${var.name_prefix}-sagemaker-inline"
  role   = aws_iam_role.sm_role.id
  policy = data.aws_iam_policy_document.sm_inline.json
}

# Lambda Execution Role
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-ml-alert-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_inline" {
  # Logs
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["*"]
  }
  # Custom metrics
  statement {
    effect  = "Allow"
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  # Read predictions
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.artifacts_bucket_name}/ml/predictions/*"]
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  name   = "${var.name_prefix}-ml-alert-lambda-inline"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}

data "aws_iam_policy_document" "lambda_sns" {
  count = var.sns_topic_arn != null ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

resource "aws_iam_role_policy" "lambda_sns" {
  count  = var.sns_topic_arn != null ? 1 : 0
  name   = "${var.name_prefix}-ml-alert-lambda-sns"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_sns[0].json
}
