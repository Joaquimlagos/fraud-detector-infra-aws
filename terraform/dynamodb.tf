# ============================================
# AWS DYNAMODB
# ============================================

# Tabela de Usuários
resource "aws_dynamodb_table" "users" {
  name         = "${var.project_name}-users-${var.environment}"
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
    Name    = "${var.project_name}-users-${var.environment}"
    Service = "dynamodb"
  }
}

# Tabela de Transações
resource "aws_dynamodb_table" "transactions" {
  name         = "${var.project_name}-transactions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  # FIX (item 6): transactionId sozinho como hash_key. Ele já é único
  # globalmente (UUID gerado pela API), então um range_key composto com
  # userId não agregava nada — só forçava toda leitura por transactionId
  # a também informar userId sem necessidade real.
  hash_key = "transactionId"

  attribute {
    name = "transactionId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "occurredAt"
    type = "S"
  }

  # FIX (item 5): GSI agora tem range_key (occurredAt), permitindo Query
  # com BETWEEN direto no banco para regras de velocidade/padrão
  # ("transações do usuário X nos últimos N minutos"), em vez de trazer
  # o histórico inteiro do usuário e filtrar na aplicação.
  global_secondary_index {
    name            = "userId-occurredAt-index"
    hash_key        = "userId"
    range_key       = "occurredAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  tags = {
    Name    = "${var.project_name}-transactions-${var.environment}"
    Service = "dynamodb"
  }
}
