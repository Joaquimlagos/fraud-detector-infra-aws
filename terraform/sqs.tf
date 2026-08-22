# ============================================
# AWS SQS
# ============================================

# Dead Letter Queue para mensagens não processadas
resource "aws_sqs_queue" "transaction_dlq" {
  name                      = "${var.project_name}-transaction-queue-${var.environment}-dlq"
  message_retention_seconds = 1209600 # 14 dias

  tags = {
    Name    = "${var.project_name}-transaction-queue-${var.environment}-dlq"
    Service = "sqs"
  }
}

# Fila principal de transações
resource "aws_sqs_queue" "transactions" {
  name                       = "${var.project_name}-transaction-queue-${var.environment}"
  delay_seconds              = 0
  max_message_size           = 262144 # 256 KB
  message_retention_seconds  = 86400  # 1 dia
  receive_wait_time_seconds  = 10     # Long polling

  # Redrive para a DLQ é automático a partir daqui — não precisa (e não
  # deveria) de uma resource policy manual para isso.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transaction_dlq.arn
    maxReceiveCount     = 3
  })

  # FIX (item 2): bloco `policy` removido. O original liberava
  # "lambda.amazonaws.com" a fazer sqs:SendMessage na fila DLQ, o que não
  # corresponde a nenhuma interação real: quem publica em `transactions` é
  # a API Java via SDK com credenciais IAM próprias (não a Lambda, que só
  # consome), e o acesso de consumo da Lambda já está coberto pela IAM
  # policy `sqs_access` anexada à sua role em iam.tf. Uma resource policy
  # aqui só seria necessária se outro serviço/conta externo precisasse
  # publicar diretamente na fila.

  tags = {
    Name    = "${var.project_name}-transaction-queue-${var.environment}"
    Service = "sqs"
  }
}
