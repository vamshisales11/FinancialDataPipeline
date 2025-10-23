resource "aws_cloudwatch_metric_alarm" "glue_failed_alarm" {
  provider            = aws.notags
  alarm_name          = "${var.name_prefix}-alarm-glue-failed"
  alarm_description   = "Alert on Glue FAILED/TIMEOUT events via EventBridge"
  namespace           = "AWS/Events"
  metric_name         = "MatchedEvents"
  dimensions          = { RuleName = aws_cloudwatch_event_rule.glue_failed.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  # Use precomputed list (either [] or [arn]) to avoid inline ternary
  alarm_actions = local.alarm_actions_list
  ok_actions    = local.alarm_actions_list
}