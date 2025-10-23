resource "aws_cloudwatch_event_rule" "datasync_failed" {
  provider      = aws.notags
  name          = "${var.name_prefix}-datasync-failed"
  description   = "DataSync task execution failures for ${var.name_prefix}"
  event_pattern = jsonencode(local.datasync_pattern)
}

resource "aws_cloudwatch_event_target" "datasync_failed_to_sns" {
  count     = var.enable_alerts && local.alerts_topic_arn != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.datasync_failed.name
  target_id = "sns"
  arn       = local.alerts_topic_arn

  input_transformer {
    input_paths = {
      exec  = "$.detail.TaskExecutionArn"
      task  = "$.detail.TaskArn"
      state = "$.detail.State"
      time  = "$.time"
      acct  = "$.account"
      reg   = "$.region"
    }
    input_template = <<EOT
{"alert":"DataSyncFailed","task":"<task>","execution":"<exec>","state":"<state>","time":"<time>","account":"<acct>","region":"<reg>"}
EOT
  }
}