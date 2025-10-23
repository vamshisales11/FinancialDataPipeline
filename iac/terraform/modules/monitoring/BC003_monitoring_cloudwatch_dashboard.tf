resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.name_prefix}-pipeline"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "text",
        "x" : 0, "y" : 0, "width" : 24, "height" : 2,
        "properties" : {
          "markdown" : "# BC003 Pipeline Monitoring\nGlue/DataSync failure signals via EventBridge (MatchedEvents)"
        }
      },
      {
        "type" : "metric",
        "x" : 0, "y" : 2, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Glue Failures (MatchedEvents)",
          "metrics" : [
            ["AWS/Events", "MatchedEvents", "RuleName", "${aws_cloudwatch_event_rule.glue_failed.name}"]
          ],
          "region" : var.region, "stat" : "Sum", "period" : 300, "view" : "timeSeries", "stacked" : false
        }
      },
      {
        "type" : "metric",
        "x" : 12, "y" : 2, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "DataSync Failures (MatchedEvents)",
          "metrics" : [
            ["AWS/Events", "MatchedEvents", "RuleName", "${aws_cloudwatch_event_rule.datasync_failed.name}"]
          ],
          "region" : var.region, "stat" : "Sum", "period" : 300, "view" : "timeSeries", "stacked" : false
        }
      }
    ]
  })
}