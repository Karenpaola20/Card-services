resource "aws_lambda_function" "card_approval_worker" {
  function_name = "card-approval-worker"

  role = aws_iam_role.card_lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"

  timeout = 10

  filename = "${path.module}/lambdas/create-request-card-lambda/card-worker.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/create-request-card-lambda/card-worker.zip")

  environment {
    variables = {
      CARD_TABLE = aws_dynamodb_table.card_table.name
      TRANSACTION_TABLE = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_event_source_mapping" "card_sqs_trigger" {

  event_source_arn = aws_sqs_queue.create_request_card_sqs.arn
  function_name    = aws_lambda_function.card_approval_worker.arn

  batch_size = 1
}

//Save
resource "aws_lambda_function" "card_transaction_save_lambda" {
  function_name = "card-transaction-save-lambda"

  role = aws_iam_role.card_lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"

  filename = "${path.module}/lambdas/card-transaction-save-lambda/card-transaction-save.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/card-transaction-save-lambda/card-transaction-save.zip")

  environment {
    variables = {
      CARD_TABLE        = aws_dynamodb_table.card_table.name
      TRANSACTION_TABLE = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_api_gateway_integration" "transaction_integration" {

  rest_api_id = aws_api_gateway_rest_api.transaction_api.id
  resource_id = aws_api_gateway_resource.transactions_card_id.id
  http_method = aws_api_gateway_method.transaction_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.card_transaction_save_lambda.invoke_arn

}

resource "aws_lambda_permission" "apigw_transaction_lambda" {

  statement_id  = "AllowAPIGatewayInvokeTransaction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_transaction_save_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

//Purchase
resource "aws_lambda_permission" "purchase_permission" {

  statement_id  = "AllowAPIGatewayInvokePurchase"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.purchase_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"

}

resource "aws_lambda_function" "purchase_lambda" {

  function_name = "purchase-lambda"

  role = aws_iam_role.card_lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"

  timeout = 10

  filename = "${path.module}/lambdas/card-purchase-lambda/purchase.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/card-purchase-lambda/purchase.zip")

  environment {
    variables = {
      CARD_TABLE        = aws_dynamodb_table.card_table.name
      TRANSACTION_TABLE = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

//Activate
resource "aws_lambda_function" "card_activate_lambda" {
  function_name = "card-activate-lambda"
  
  role = aws_iam_role.card_lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"

  timeout = 10

  filename = "${path.module}/lambdas/card-activate-lambda/card-activate.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/card-activate-lambda/card-activate.zip")

  environment {
    variables = {
      CARD_TABLE              = aws_dynamodb_table.card_table.name
      TRANSACTION_TABLE       = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL  = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "card_activate_permission" {
  statement_id  = "AllowAPIGatewayInvokeCardActivate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_activate_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

//Paid
resource "aws_lambda_function" "card_paid_credit_card_lambda" {
  function_name = "card-paid-credit-card-lambda"
  role          = aws_iam_role.card_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  filename = "${path.module}/lambdas/card-paid-credit-card-lambda/card-paid-credit-card.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/card-paid-credit-card-lambda/card-paid-credit-card.zip")

  environment {
    variables = {
      CARD_TABLE             = aws_dynamodb_table.card_table.name
      TRANSACTION_TABLE      = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "card_paid_permission" {
  statement_id = "AllowAPIGatewayInvokeCardPaid"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_paid_credit_card_lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}

//Report
resource "aws_lambda_function" "card_get_report_lambda" {
  function_name = "card-get-report-lambda"
  role = aws_iam_role.card_lambda_role.arn

  handler = "index.handler"
  runtime = "nodejs20.x"

  timeout = 15

  filename = "${path.module}/lambdas/card-get-report-lambda/card-get-report.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/card-get-report-lambda/card-get-report.zip")

  environment {
    variables = {
      TRANSACTION_TABLE = aws_dynamodb_table.transaction_table.name
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/537236557851/notification-email-sqs"
    }
  }
}

resource "aws_lambda_permission" "card_get_report_permission" {
  statement_id = "AllowAPIGatewayInvokeCardReport"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.card_get_report_lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.transaction_api.execution_arn}/*/*"
}