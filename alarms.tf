module "alb-alarms" {
  source  = "lorenzoaiello/alb-alarms/aws"
  version = "1.0.0"
  load_balancer_id = module.alb.this_lb_arn
  target_group_id = element(module.alb.target_group_arns, 0)
  response_time_threshold = 100
  actions_alarm =  [aws_sns_topic.refinery_alb_alert.id]
  actions_ok = [aws_sns_topic.refinery_alb_alert.id]
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
