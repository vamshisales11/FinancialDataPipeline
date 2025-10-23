resource "aws_cloudwatch_metric_alarm" "datasync_failed_alarm" {
  provider            = aws.notags
  alarm_name          = "${var.name_prefix}-alarm-datasync-failed"
  alarm_description   = "Alert on DataSync ERROR/CANCELED events via EventBridge"
  namespace           = "AWS/Events"
  metric_name         = "MatchedEvents"
  dimensions          = { RuleName = aws_cloudwatch_event_rule.datasync_failed.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = local.alarm_actions_list
  ok_actions    = local.alarm_actions_list
}