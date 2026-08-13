# ============================================
# AWS IAM - Roles e Policies
# ============================================

# Role da Lambda
resource "aws_iam_role" "lambda_role" {
  name = "fraud-detection-lambda-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "fraud-detection-lambda-role-${var.environment}"
    Service = "iam"
  }
}

# Policy para acesso ao DynamoDB
resource "aws_iam_policy" "dynamodb_access" {
  name        = "fraud-detection-dynamodb-${var.environment}"
  description = "Permissões DynamoDB para a Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.transactions.arn,
          "${aws_dynamodb_table.transactions.arn}/index/*"
        ]
      }
    ]
  })
}

# Policy para acesso ao SQS
resource "aws_iam_policy" "sqs_access" {
  name        = "fraud-detection-sqs-${var.environment}"
  description = "Permissões SQS para a Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.transactions.arn
      }
    ]
  })
}

# Policy para publicar no SNS
resource "aws_iam_policy" "sns_publish" {
  name        = "fraud-detection-sns-${var.environment}"
  description = "Permissões SNS para a Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.fraud_alerts.arn
      }
    ]
  })
}

# Policy para CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "fraud-detection-logs-${var.environment}"
  description = "Permissões CloudWatch Logs para a Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Anexar policies à role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sqs_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}