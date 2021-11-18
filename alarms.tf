locals {
  target_group_name = element(module.alb.target_group_arn_suffixes, 0)
}

resource "aws_cloudwatch_metric_alarm" "target_response_time_average" {
  alarm_name          = "alb-tg-${local.target_group_name}-highResponseTime"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Average API response time is too high"
  alarm_actions       = ["${aws_sns_topic.refinery_alb_alert.id}"]
  ok_actions          = ["${aws_sns_topic.refinery_alb_alert.id}"]

  dimensions = {
    "LoadBalancer" = module.alb.this_lb_arn_suffix
    "TargetGroup"  = local.target_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "httpcode_lb_5xx_count" {
  alarm_name          = "alb-${module.alb.this_lb_arn_suffix}-high5XXCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Average API 5XX load balancer error code count is too high"
  alarm_actions       = ["${aws_sns_topic.refinery_alb_alert.id}"]
  ok_actions          = ["${aws_sns_topic.refinery_alb_alert.id}"]

  dimensions = {
    "LoadBalancer" = module.alb.this_lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_host_count" {
  alarm_name          = "tg-${local.target_group_name}-unhealthyHostCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Unhealthy host count behind ECS is more than or equal to 1"
  alarm_actions       = ["${aws_sns_topic.refinery_alb_alert.id}"]
  ok_actions          = ["${aws_sns_topic.refinery_alb_alert.id}"]

  dimensions = {
    "LoadBalancer" = module.alb.this_lb_arn_suffix
    "TargetGroup"  = local.target_group_name
  }
}

resource "aws_sns_topic" "refinery_alb_alert" {
  name            = "refinery_alb_alert"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

resource "aws_sns_topic_subscription" "refinery_alb_pd_alert" {
  endpoint  = var.pd_alert_target
  topic_arn = aws_sns_topic.refinery_alb_alert.arn
  protocol  = "https"
}

variable "pd_alert_target" {
  description = "https endpoint to trigger alert to"
  default     = ""
  type        = string
}
