variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "artifacts_bucket_name" {
  type = string
}

# Toggles (keep off until paths are ready)
variable "enable_training" {
  type    = bool
  default = false
}

variable "enable_model" {
  type    = bool
  default = false
}

variable "enable_batch_transform" {
  type    = bool
  default = false
}

# Run/version identifier
variable "run_id" {
  type    = string
  default = "v1"
}

# RCF (unsupervised) container and feature dimension (3 numeric columns)
variable "rcf_image_uri" {
  type    = string
  default = "632365934929.dkr.ecr.us-east-1.amazonaws.com/randomcutforest:1"
}

variable "feature_dim" {
  type    = number
  default = 3
}

# Optional: supply an existing model artifact to skip training
variable "existing_model_data_url" {
  type    = string
  default = null
}

# Lambda packaging (zip file you build locally)
variable "lambda_zip_path" {
  type    = string
  default = null
}

# Alerts
variable "threshold" {
  type    = number
  default = 0.9
}

variable "sns_topic_arn" {
  type    = string
  default = null
}

locals {
  base_prefix           = "ml"
  train_s3_uri          = "s3://${var.artifacts_bucket_name}/${local.base_prefix}/features/train/"
  inference_s3_uri      = "s3://${var.artifacts_bucket_name}/${local.base_prefix}/features/inference/"
  model_output_s3_uri   = "s3://${var.artifacts_bucket_name}/${local.base_prefix}/models/${var.run_id}/"
  predictions_output_s3 = "s3://${var.artifacts_bucket_name}/${local.base_prefix}/predictions/${var.run_id}/"

  # Terraform no longer creates the training job, so take the model artifact URL from the variable
  model_data_url = var.existing_model_data_url
}

