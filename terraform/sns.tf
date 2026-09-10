resource "aws_sns_topic" "fraud_alerts" {
  name = "${var.project_name}-fraud-alerts-${var.environment}"

  tags = {
    Name    = "${var.project_name}-fraud-alerts-${var.environment}"
    Service = "sns"
  }
}

resource "aws_sns_topic_subscription" "fraud_alerts_email" {
  topic_arn = aws_sns_topic.fraud_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
