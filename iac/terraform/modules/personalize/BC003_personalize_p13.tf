# Dataset Group
resource "aws_personalize_dataset_group" "this" {
  provider = aws.notags
  name     = local.dataset_group_name
}

# Interactions schema (3 columns: USER_ID, ITEM_ID, TIMESTAMP)
resource "aws_personalize_schema" "interactions" {
  provider = aws.notags
  name     = "${var.name_prefix}-int-schema"
  schema   = <<JSON
{
  "type":"record",
  "name":"Interactions",
  "namespace":"com.amazonaws.personalize.schema",
  "fields":[
    {"name":"USER_ID","type":"string"},
    {"name":"ITEM_ID","type":"string"},
    {"name":"TIMESTAMP","type":"long"}
  ],
  "version":"1.0"
}
JSON
}

# Interactions dataset
resource "aws_personalize_dataset" "interactions" {
  provider           = aws.notags
  name               = "${var.name_prefix}-interactions"
  dataset_group_arn  = aws_personalize_dataset_group.this.arn
  dataset_type       = "INTERACTIONS"
  schema_arn         = aws_personalize_schema.interactions.arn
}

# Import interactions from S3
resource "aws_personalize_dataset_import_job" "interactions" {
  provider  = aws.notags
  job_name  = "${var.name_prefix}-int-import"
  dataset_arn = aws_personalize_dataset.interactions.arn

  data_source {
    data_location = local.interactions_path
  }
  role_arn = aws_iam_role.personalize_role.arn
}

# Solution (User-Personalization)
resource "aws_personalize_solution" "this" {
  provider           = aws.notags
  name               = local.solution_name
  dataset_group_arn  = aws_personalize_dataset_group.this.arn
  recipe_arn         = var.recipe_arn

  depends_on = [aws_personalize_dataset_import_job.interactions]
}

# Train solution version
resource "aws_personalize_solution_version" "v1" {
  provider    = aws.notags
  solution_arn = aws_personalize_solution.this.arn
  # waits for ACTIVE state
}

# Optional batch inference job (writes recs to S3)
resource "aws_personalize_batch_inference_job" "batch" {
  count                 = var.enable_batch_inference ? 1 : 0
  provider              = aws.notags
  job_name              = "${var.name_prefix}-batch-recs"
  solution_version_arn  = aws_personalize_solution_version.v1.arn
  role_arn              = aws_iam_role.personalize_role.arn

  job_input {
    s3_data_source { path = local.batch_input_path }
  }
  job_output {
    s3_data_destination { path = local.batch_output_path }
  }

  # Optional: limit number of results per user (defaults usually 25)
  num_results = var.batch_num_results
}