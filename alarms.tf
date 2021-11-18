resource "aws_cloudwatch_metric_alarm" "target_response_time_average" {
  alarm_name          = "alb-tg-${var.target_group_id}-highResponseTime"
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
    "TargetGroup"  = element(module.alb.target_group_arns, 0)
    "LoadBalancer" = module.alb.this_lb_arn
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
