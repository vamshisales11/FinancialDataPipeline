resource "aws_glue_catalog_database" "bronze" {
  name = "${var.name_prefix}_bronze_db"
}

resource "aws_glue_crawler" "bronze_core" {
  name          = "${var.name_prefix}-bronze-core"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.bronze.name
  s3_target {
    path = "s3://${aws_s3_bucket.bronze.bucket}/core_banking/"
  }
  configuration = jsonencode({ Version = 1.0, Grouping = { TableLevelConfiguration = 2 } })
  schedule      = "cron(0 2 * * ? *)"
  tags          = local.common_tags
}

resource "aws_glue_crawler" "bronze_loan" {
  name          = "${var.name_prefix}-bronze-loan"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.bronze.name
  s3_target {
    path = "s3://${aws_s3_bucket.bronze.bucket}/loan_mgmt/"
  }
  configuration = jsonencode({ Version = 1.0, Grouping = { TableLevelConfiguration = 2 } })
  schedule      = "cron(10 2 * * ? *)"
  tags          = local.common_tags
}

resource "aws_glue_crawler" "bronze_txn" {
  name          = "${var.name_prefix}-bronze-txn"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.bronze.name
  s3_target {
    path = "s3://${aws_s3_bucket.bronze.bucket}/txn_stream/"
  }
  configuration = jsonencode({ Version = 1.0, Grouping = { TableLevelConfiguration = 2 } })
  schedule      = "cron(20 2 * * ? *)"
  tags          = local.common_tags
}