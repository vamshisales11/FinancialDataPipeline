# Lambda for threshold alerts
resource "aws_lambda_function" "ml_alert" {
  count            = var.lambda_zip_path != null ? 1 : 0
  function_name    = "${var.name_prefix}-ml-threshold-alert"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout          = 60
  environment {
  variables = {
    THRESHOLD     = tostring(var.threshold)
    NAMESPACE     = "BC003/ML"
    SNS_TOPIC_ARN = var.sns_topic_arn != null ? var.sns_topic_arn : ""
      }
    }

}

# EventBridge: trigger Lambda when predictions are written
resource "aws_cloudwatch_event_rule" "predictions_created" {
  provider    = aws.notags
  name        = "${var.name_prefix}-ml-predictions-created"
  description = "Invoke Lambda on predictions written to artifacts bucket"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [var.artifacts_bucket_name] },
      "object" : { "key" : [{ "prefix" : "ml/predictions/" }] }
    }
  })
}

resource "aws_cloudwatch_event_target" "predictions_to_lambda" {
  count     = var.lambda_zip_path != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.predictions_created.name
  target_id = "lambda"
  arn       = aws_lambda_function.ml_alert[0].arn
}

resource "aws_lambda_permission" "allow_events" {
  count         = var.lambda_zip_path != null ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ml_alert[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.predictions_created.arn
}