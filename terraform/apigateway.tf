resource "aws_api_gateway_rest_api" "transaction_api" {
  name = "transaction-api"
}

resource "aws_api_gateway_resource" "transactions" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "transactions"

}

resource "aws_api_gateway_resource" "transactions_save" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.transactions.id
  path_part   = "save"

}

resource "aws_api_gateway_resource" "transactions_card_id" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.transactions_save.id
  path_part   = "{card_id}"

}

resource "aws_api_gateway_method" "transaction_post" {

  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.transactions_card_id.id
  http_method   = "POST"
  authorization = "NONE"

}

resource "aws_api_gateway_deployment" "transaction_deployment" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.transactions.id,
      aws_api_gateway_resource.transactions_save.id,
      aws_api_gateway_resource.transactions_card_id.id,
      aws_api_gateway_method.transaction_post.id,
      aws_api_gateway_integration.transaction_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.transaction_integration
  ]

}

resource "aws_api_gateway_stage" "transaction_stage" {

  deployment_id = aws_api_gateway_deployment.transaction_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  stage_name    = "dev"

}