# ============================================
# AWS SQS
# ============================================

# Dead Letter Queue para mensagens não processadas
resource "aws_sqs_queue" "transaction_dlq" {
  name                      = "transaction-queue-${var.environment}-dlq"
  message_retention_seconds = 1209600  # 14 dias
  
  tags = {
    Name = "transaction-queue-${var.environment}-dlq"
    Service = "sqs"
  }
}

# Fila principal de transações
resource "aws_sqs_queue" "transactions" {
  name                      = "transaction-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144  # 256 KB
  message_retention_seconds = 86400   # 1 dia
  receive_wait_time_seconds = 10      # Long polling
  
  # Configuração de redrive para DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transaction_dlq.arn
    maxReceiveCount     = 3
  })
  
  # Política de acesso (opcional - ajuste conforme necessidade)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.transaction_dlq.arn
      }
    ]
  })
  
  tags = {
    Name = "transaction-queue-${var.environment}"
    Service = "sqs"
  }
}