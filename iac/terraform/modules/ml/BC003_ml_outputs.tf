# Key S3 paths for CLI use
output "train_input_s3" {
  value       = local.train_s3_uri
  description = "S3 path for training features (CSV)"
}

output "inference_input_s3" {
  value       = local.inference_s3_uri
  description = "S3 path for inference features (CSV)"
}

output "predictions_output_s3" {
  value       = local.predictions_output_s3
  description = "S3 path where Batch Transform writes predictions"
}

# Optional model name (if you let Terraform create the SageMaker Model)
output "model_name" {
  value       = try(aws_sagemaker_model.rcf[0].name, null)
  description = "SageMaker model name (null if not created by Terraform)"
}

# Handy infra outputs
output "ml_alert_lambda_name" {
  value       = try(aws_lambda_function.ml_alert[0].function_name, null)
  description = "Lambda that inspects predictions and posts metrics"
}

output "predictions_event_rule_name" {
  value       = aws_cloudwatch_event_rule.predictions_created.name
  description = "EventBridge rule that triggers Lambda on S3 Object Created under ml/predictions/"
}