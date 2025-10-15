#create glue db + optinal crawlers

resource "aws_glue_catalog_database" "silver" {
  name        = "${var.name_prefix}_silver_db"
  description = "Silver (trusted) layer database"
}

resource "aws_glue_crawler" "silver_core" {
  name          = "${var.name_prefix}-silver-core"
  role          = aws_iam_role.glue_etl_role.arn
  database_name = aws_glue_catalog_database.silver.name
  s3_target { path = "s3://${aws_s3_bucket.silver.bucket}/core_banking/" }
  schedule      = "cron(0 3 * * ? *)"
  tags          = local.common_tags
}