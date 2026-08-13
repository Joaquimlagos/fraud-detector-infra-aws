# ============================================
# AWS DYNAMODB
# ============================================

# Tabela de Usuários
resource "aws_dynamodb_table" "users" {
  name         = "users-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  
  attribute {
    name = "userId"
    type = "S"
  }
  
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
  
  tags = {
    Name = "users-${var.environment}"
    Service = "dynamodb"
  }
}

# Tabela de Transações
resource "aws_dynamodb_table" "transactions" {
  name         = "transactions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transactionId"
  range_key    = "userId"
  
  attribute {
    name = "transactionId"
    type = "S"
  }
  
  attribute {
    name = "userId"
    type = "S"
  }
  
  # GSI para consultar transações por usuário
  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
  
  tags = {
    Name = "transactions-${var.environment}"
    Service = "dynamodb"
  }
}