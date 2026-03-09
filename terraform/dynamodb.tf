resource "aws_dynamodb_table" "card_table" {
  name = "card-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "uuid"
  range_key = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }
  
  attribute {
    name = "createdAt"
    type = "S"
  }
}

resource "aws_dynamodb_table" "transaction_table" {

  name         = "transaction-table"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "uuid"
  range_key = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  attribute {
    name = "cardId"
    type = "S"
  }

  global_secondary_index {

    name            = "cardId-index"
    hash_key        = "cardId"
    projection_type = "ALL"

  }

}