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

resource "aws_dynamodb_table" "transactions" {
  name         = "${var.project_name}-transactions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

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
