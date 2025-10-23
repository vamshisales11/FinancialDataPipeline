resource "aws_cloudwatch_event_rule" "glue_failed" {
  provider      = aws.notags
  name          = "${var.name_prefix}-glue-failed"
  description   = "Glue job failures/timeouts for ${var.name_prefix}"
  event_pattern = jsonencode(local.glue_pattern)
}

resource "aws_cloudwatch_event_target" "glue_failed_to_sns" {
  count     = var.enable_alerts && local.alerts_topic_arn != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.glue_failed.name
  target_id = "sns"
  arn       = local.alerts_topic_arn

  input_transformer {
    input_paths = {
      job   = "$.detail.jobName"
      state = "$.detail.state"
      run   = "$.detail.jobRunId"
      time  = "$.time"
      acct  = "$.account"
      reg   = "$.region"
    }
    input_template = <<EOT
{"alert":"GlueJobFailed","job":"<job>","state":"<state>","run":"<run>","time":"<time>","account":"<acct>","region":"<reg>"}
EOT
  }
}