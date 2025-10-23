variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "glue_job_names" {
  description = "Glue job names to watch for FAILED/TIMEOUT. If empty, monitors all jobs."
  type        = list(string)
  default     = []
}

variable "datasync_task_arns" {
  description = "DataSync Task ARNs to watch for ERROR/CANCELED. If empty, monitors all tasks."
  type        = list(string)
  default     = []
}

variable "enable_alerts" {
  type    = bool
  default = false
}

variable "create_sns_topic" {
  type    = bool
  default = false
}

variable "sns_topic_arn" {
  type    = string
  default = null
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

locals {
  # Glue pattern (include jobName only if provided)
  glue_pattern_base = {
    source        = ["aws.glue"]
    "detail-type" = ["Glue Job State Change"]
    detail = {
      state = ["FAILED", "TIMEOUT"]
    }
  }
  glue_detail_extra    = length(var.glue_job_names) > 0 ? { jobName = var.glue_job_names } : {}
  glue_detail_combined = merge(local.glue_pattern_base.detail, local.glue_detail_extra)
  glue_pattern         = merge(local.glue_pattern_base, { detail = local.glue_detail_combined })

  # DataSync pattern (include TaskArn only if provided)
  datasync_pattern_base = {
    source        = ["aws.datasync"]
    "detail-type" = ["DataSync Task Execution State Change"]
    detail = {
      State = ["ERROR", "CANCELED"]
    }
  }
  datasync_detail_extra    = length(var.datasync_task_arns) > 0 ? { TaskArn = var.datasync_task_arns } : {}
  datasync_detail_combined = merge(local.datasync_pattern_base.detail, local.datasync_detail_extra)
  datasync_pattern         = merge(local.datasync_pattern_base, { detail = local.datasync_detail_combined })

  # If alerts enabled:
  # - If creating topic, use the created topic ARN (or null if not created)
  # - Else, use provided sns_topic_arn (or null)
  created_topic_arn = try(aws_sns_topic.alerts[0].arn, null)
  alerts_topic_arn  = var.enable_alerts ? (var.create_sns_topic ? local.created_topic_arn : var.sns_topic_arn) : null

  # Turn optional ARN into [] or [arn] for alarmActions without inline ternary in resources
  alarm_actions_list = local.alerts_topic_arn == null ? [] : [local.alerts_topic_arn]
}
