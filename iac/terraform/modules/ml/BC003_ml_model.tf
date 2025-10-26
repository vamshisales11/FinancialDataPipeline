
resource "aws_sagemaker_model" "rcf" {
  count = var.enable_model && var.existing_model_data_url != null ? 1 : 0
  name  = "${var.name_prefix}-rcf-model-${var.run_id}"

  primary_container {
    image          = var.rcf_image_uri
    mode           = "SingleModel"
    model_data_url = var.existing_model_data_url
  }

  execution_role_arn = aws_iam_role.sm_role.arn
}
