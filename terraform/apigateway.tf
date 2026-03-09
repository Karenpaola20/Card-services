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
      aws_api_gateway_resource.purchase.id,
      aws_api_gateway_resource.card.id,
      aws_api_gateway_resource.card_activate.id,
      aws_api_gateway_resource.card_pay.id,
      aws_api_gateway_resource.card_pay_card_id.id,

      aws_api_gateway_method.transaction_post.id,
      aws_api_gateway_method.purchase_post.id,
      aws_api_gateway_method.card_activate_post.id,
      aws_api_gateway_method.card_pay_post.id,

      aws_api_gateway_integration.transaction_integration.id,
      aws_api_gateway_integration.purchase_integration.id,
      aws_api_gateway_integration.card_activate_integration.id,
      aws_api_gateway_integration.card_pay_integration.id,
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

//Purchase
resource "aws_api_gateway_resource" "purchase" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part   = "purchase"

}

resource "aws_api_gateway_method" "purchase_post" {

  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.purchase.id
  http_method   = "POST"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "purchase_integration" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.purchase.id
  http_method = aws_api_gateway_method.purchase_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.purchase_lambda.invoke_arn

}

//Card activate
resource "aws_api_gateway_resource" "card" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id = aws_api_gateway_rest_api.transaction_api.root_resource_id
  path_part = "card"
}

resource "aws_api_gateway_resource" "card_activate" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id = aws_api_gateway_resource.card.id
  path_part = "activate"
}

resource "aws_api_gateway_method" "card_activate_post" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_activate.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "card_activate_integration" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_activate.id
  http_method = aws_api_gateway_method.card_activate_post.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"

  uri = aws_lambda_function.card_activate_lambda.invoke_arn
}

//Save
resource "aws_api_gateway_resource" "card_pay" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.card.id
  path_part   = "paid"
}

resource "aws_api_gateway_resource" "card_pay_card_id" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  parent_id   = aws_api_gateway_resource.card_pay.id
  path_part   = "{card_id}"

}

resource "aws_api_gateway_method" "card_pay_post" {
  rest_api_id   = aws_api_gateway_rest_api.transaction_api.id
  resource_id   = aws_api_gateway_resource.card_pay_card_id.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "card_pay_integration" {
  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.card_pay_card_id.id
  http_method = aws_api_gateway_method.card_pay_post.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"
  
  uri = aws_lambda_function.card_paid_credit_card_lambda.invoke_arn
}