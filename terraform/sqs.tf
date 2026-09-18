resource "aws_sqs_queue" "transaction_dlq" {
  name                      = "${var.project_name}-transaction-queue-${var.environment}-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name    = "${var.project_name}-transaction-queue-${var.environment}-dlq"
    Service = "sqs"
  }
}

resource "aws_sqs_queue" "transactions" {
  name                      = "${var.project_name}-transaction-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.transaction_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = "${var.project_name}-transaction-queue-${var.environment}"
    Service = "sqs"
  }
}

resource "aws_sqs_queue" "suspicious_transactions_dlq" {
  name                      = "${var.project_name}-suspicious-transactions-queue-${var.environment}-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name    = "${var.project_name}-suspicious-transactions-queue-${var.environment}-dlq"
    Service = "sqs"
  }
}

resource "aws_sqs_queue" "suspicious_transactions" {
  name                      = "${var.project_name}-suspicious-transactions-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.suspicious_transactions_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = "${var.project_name}-suspicious-transactions-queue-${var.environment}"
    Service = "sqs"
  }
}
