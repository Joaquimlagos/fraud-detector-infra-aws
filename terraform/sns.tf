# ============================================
# AWS SNS
# ============================================

# Tópico para alertas de fraude
resource "aws_sns_topic" "fraud_alerts" {
  name = "fraud-alerts-${var.environment}"
  
  # Política de acesso
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.fraud_alerts.arn
      }
    ]
  })
  
  tags = {
    Name = "fraud-alerts-${var.environment}"
    Service = "sns"
  }
}

# Assinatura de email para alertas (opcional - configure conforme necessário)
resource "aws_sns_topic_subscription" "fraud_alerts_email" {
  count     = var.environment == "prod" ? 1 : 0
  topic_arn = aws_sns_topic.fraud_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}