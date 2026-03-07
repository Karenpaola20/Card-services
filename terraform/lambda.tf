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
    }
  }
}

resource "aws_lambda_event_source_mapping" "card_sqs_trigger" {

  event_source_arn = aws_sqs_queue.create_request_card_sqs.arn
  function_name    = aws_lambda_function.card_approval_worker.arn

  batch_size = 1
}