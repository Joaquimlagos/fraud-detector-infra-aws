# ============================================
# OUTPUTS
# ============================================

# DynamoDB
output "users_table_name" {
  description = "Nome da tabela de usuários"
  value       = aws_dynamodb_table.users.name
}

output "transactions_table_name" {
  description = "Nome da tabela de transações"
  value       = aws_dynamodb_table.transactions.name
}

# SQS
output "transaction_queue_url" {
  description = "URL da fila de transações"
  value       = aws_sqs_queue.transactions.url
}

output "transaction_queue_arn" {
  description = "ARN da fila de transações"
  value       = aws_sqs_queue.transactions.arn
}

output "transaction_dlq_url" {
  description = "URL da dead letter queue"
  value       = aws_sqs_queue.transaction_dlq.url
}

# SNS
output "fraud_alerts_topic_arn" {
  description = "ARN do tópico de alertas de fraude"
  value       = aws_sns_topic.fraud_alerts.arn
}

