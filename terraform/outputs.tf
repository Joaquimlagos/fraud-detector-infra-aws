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

# SNS
output "fraud_alerts_topic_arn" {
  description = "ARN do tópico de alertas de fraude"
  value       = aws_sns_topic.fraud_alerts.arn
}

# Lambda
output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.fraud_detection.function_name
}

output "lambda_function_arn" {
  description = "ARN da função Lambda"
  value       = aws_lambda_function.fraud_detection.arn
}