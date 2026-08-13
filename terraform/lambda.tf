# ============================================
# AWS LAMBDA
# ============================================

# Pacote do código Lambda (placeholder - ajuste para seu repositório Python)
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda-code/"
  output_path = "${path.module}/lambda-function.zip"
}

# Função Lambda de detecção de fraude
resource "aws_lambda_function" "fraud_detection" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "fraud-detection-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256
  
  environment {
    variables = {
      TRANSACTIONS_TABLE = aws_dynamodb_table.transactions.name
      USERS_TABLE        = aws_dynamodb_table.users.name
      SNS_TOPIC_ARN      = aws_sns_topic.fraud_alerts.arn
      SQS_QUEUE_URL      = aws_sqs_queue.transactions.url
      ENVIRONMENT        = var.environment
    }
  }
  
  tags = {
    Name = "fraud-detection-${var.environment}"
    Service = "lambda"
  }
}

# Trigger SQS para a Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.transactions.arn
  function_name    = aws_lambda_function.fraud_detection.arn
  batch_size       = 10
  enabled          = true
}