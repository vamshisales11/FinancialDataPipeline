# Optional SNS (disabled by default to avoid SNS:CreateTopic AccessDenied)

resource "aws_sns_topic" "alerts" {
  count    = var.enable_alerts && var.create_sns_topic ? 1 : 0
  provider = aws.notags
  name     = "${var.name_prefix}-pipeline-alerts"
}

resource "aws_sns_topic_subscription" "emails" {
  count     = var.enable_alerts && var.create_sns_topic ? length(var.alert_emails) : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

data "aws_iam_policy_document" "sns_events" {
  count = var.enable_alerts && var.create_sns_topic ? 1 : 0

  statement {
    sid     = "AllowEventBridgePublish"
    effect  = "Allow"
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.alerts[0].arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.glue_failed.arn,
        aws_cloudwatch_event_rule.datasync_failed.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "sns_events" {
  count  = var.enable_alerts && var.create_sns_topic ? 1 : 0
  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.sns_events[0].json
}