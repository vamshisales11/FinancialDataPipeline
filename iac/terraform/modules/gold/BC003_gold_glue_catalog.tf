resource "aws_glue_catalog_database" "gold" {
  name        = "${var.name_prefix}_gold_db"
  description = "Business-ready curated data for financial analytics"
}