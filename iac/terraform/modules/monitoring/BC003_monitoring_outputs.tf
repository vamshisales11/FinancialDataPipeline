output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.pipeline.dashboard_name
}

output "glue_rule_name" {
  description = "EventBridge rule name for Glue failures"
  value       = aws_cloudwatch_event_rule.glue_failed.name
}

output "datasync_rule_name" {
  description = "EventBridge rule name for DataSync failures"
  value       = aws_cloudwatch_event_rule.datasync_failed.name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN used for alerts (null unless alerts enabled/provided)"
  value       = local.alerts_topic_arn
}