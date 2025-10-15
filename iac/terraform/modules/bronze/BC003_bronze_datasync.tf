# S3 locations (Landing → Bronze) for core_banking and loan_mgmt
resource "aws_datasync_location_s3" "landing_core" {
  s3_bucket_arn = aws_s3_bucket.landing.arn
  subdirectory  = "/core_banking"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

resource "aws_datasync_location_s3" "bronze_core" {
  s3_bucket_arn = aws_s3_bucket.bronze.arn
  subdirectory  = "/core_banking"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

resource "aws_datasync_location_s3" "landing_loan" {
  s3_bucket_arn = aws_s3_bucket.landing.arn
  subdirectory  = "/loan_mgmt"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}

resource "aws_datasync_location_s3" "bronze_loan" {
  s3_bucket_arn = aws_s3_bucket.bronze.arn
  subdirectory  = "/loan_mgmt"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_role.arn
  }
}


# DataSync tasks (Landing → Bronze) with S3-safe options (no POSIX)
resource "aws_datasync_task" "core_banking" {
  name                     = "${var.name_prefix}-ds-core-banking"
  source_location_arn      = aws_datasync_location_s3.landing_core.arn
  destination_location_arn = aws_datasync_location_s3.bronze_core.arn

  options {
    atime                  = "NONE"
    gid                    = "NONE"
    uid                    = "NONE"
    posix_permissions      = "NONE"
    mtime                  = "NONE"
    object_tags            = "PRESERVE"
    preserve_deleted_files = "PRESERVE"
    overwrite_mode         = "ALWAYS"
    task_queueing          = "ENABLED"
    transfer_mode          = "CHANGED"
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    log_level              = "OFF"
    preserve_devices       = "NONE"
  }

  schedule {
    schedule_expression = "cron(0 1 * * ? *)" # 01:00 UTC daily
  }

  tags = local.common_tags
}

resource "aws_datasync_task" "loan_mgmt" {
  name                     = "${var.name_prefix}-ds-loan-mgmt"
  source_location_arn      = aws_datasync_location_s3.landing_loan.arn
  destination_location_arn = aws_datasync_location_s3.bronze_loan.arn

  options {
    atime                  = "NONE"
    gid                    = "NONE"
    uid                    = "NONE"
    posix_permissions      = "NONE"
    mtime                  = "NONE"
    object_tags            = "PRESERVE"
    preserve_deleted_files = "PRESERVE"
    overwrite_mode         = "ALWAYS"
    task_queueing          = "ENABLED"
    transfer_mode          = "CHANGED"
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    log_level              = "OFF"
    preserve_devices       = "NONE"
  }

  schedule {
    schedule_expression = "cron(15 1 * * ? *)" # 01:15 UTC daily
  }

  tags = local.common_tags
}
