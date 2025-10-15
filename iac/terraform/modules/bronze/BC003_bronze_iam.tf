# DataSync assume role
data "aws_iam_policy_document" "datasync_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "datasync_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-datasync-s3-role"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume.json
  # no tags here
}

# DataSync access (inline policy)
data "aws_iam_policy_document" "datasync_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.landing.arn, aws_s3_bucket.bronze.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject*", "s3:PutObject*", "s3:DeleteObject*"]
    resources = ["${aws_s3_bucket.landing.arn}/*", "${aws_s3_bucket.bronze.arn}/*"]
  }
}

resource "aws_iam_role_policy" "datasync_inline" {
  name   = "${var.name_prefix}-datasync-s3-inline"
  role   = aws_iam_role.datasync_role.id
  policy = data.aws_iam_policy_document.datasync_access.json
}

# Firehose assume role
data "aws_iam_policy_document" "firehose_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-firehose-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
  # no tags here
}

# Firehose access (inline policy)
data "aws_iam_policy_document" "firehose_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [aws_s3_bucket.bronze.arn, "${aws_s3_bucket.bronze.arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "firehose_inline" {
  name   = "${var.name_prefix}-firehose-s3-inline"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_access.json
}

# Glue crawler assume role
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

resource "aws_iam_role" "glue_role" {
  provider           = aws.notags
  name               = "${var.name_prefix}-glue-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
  # no tags here
}

# Glue crawler access (inline policy)
data "aws_iam_policy_document" "glue_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.bronze.arn, "${aws_s3_bucket.bronze.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["glue:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "glue_inline" {
  name   = "${var.name_prefix}-glue-crawler-inline"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_access.json
}