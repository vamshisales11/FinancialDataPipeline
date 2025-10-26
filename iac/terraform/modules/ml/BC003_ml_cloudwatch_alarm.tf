# Optional alarm: alerts when any high-score rows are detected in a run (via metrics from Lambda)
resource "aws_cloudwatch_metric_alarm" "ml_highscore_alarm" {
  provider            = aws.notags
  alarm_name          = "${var.name_prefix}-alarm-ml-highscores-${var.run_id}"
  alarm_description   = "Anomaly scores above threshold detected (via Lambda metric HighScoreCount)"
  namespace           = "BC003/ML"
  metric_name         = "HighScoreCount"
  dimensions          = { RunId = var.run_id }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
}