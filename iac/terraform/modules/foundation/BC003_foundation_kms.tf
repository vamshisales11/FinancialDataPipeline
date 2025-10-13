resource "aws_kms_key" "data" {
  count                   = var.enable_cmk ? 1 : 0
  description             = "BC003 data CMK for S3/Glue/Firehose/Redshift"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "data_alias" {
  count         = var.enable_cmk && var.create_kms_alias ? 1 : 0
  name          = "alias/${var.name_prefix}-data-key"
  target_key_id = aws_kms_key.data[0].key_id
}