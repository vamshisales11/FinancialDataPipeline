resource "aws_iam_policy" "kms_data_use" {
  count       = var.enable_kms_data_use_policy ? 1 : 0
  name        = "${var.name_prefix}-kms-data-use"
  description = "Least-privilege KMS usage for BC003 services"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowKmsUse",
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = var.enable_cmk ? aws_kms_key.data[0].arn : "*"
      }
    ]
  })
}