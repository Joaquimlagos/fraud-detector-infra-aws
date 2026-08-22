# ============================================
# AWS SNS
# ============================================

# Tópico para alertas de fraude
#
# FIX (item 8): bloco `policy` removido. Uma resource policy no tópico só
# é necessária quando outro serviço/conta externo precisa publicar de fora
# para dentro. A Lambda já publica através da IAM policy `sns_publish`
# anexada à sua role em iam.tf, que é o mecanismo correto aqui. O policy
# original, sem uma condição SourceArn/SourceAccount, liberava qualquer
# Lambda da conta (não só a sua) a publicar neste tópico.
resource "aws_sns_topic" "fraud_alerts" {
  name = "${var.project_name}-fraud-alerts-${var.environment}"

  tags = {
    Name    = "${var.project_name}-fraud-alerts-${var.environment}"
    Service = "sns"
  }
}

# FIX (item 9): assinatura de email agora ativa em todos os ambientes
# (antes só existia em prod, o que impedia validar o fluxo ponta a ponta
# em dev antes de ir para produção).
resource "aws_sns_topic_subscription" "fraud_alerts_email" {
  topic_arn = aws_sns_topic.fraud_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
