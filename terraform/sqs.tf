resource "aws_sqs_queue" "error_create_request_card_sqs" {
  name = "error-create-request-card-sqs"
}

resource "aws_sqs_queue" "create_request_card_sqs" {
  name = "create-request-card-sqs"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.error_create_request_card_sqs.arn
    maxReceiveCount     = 3
  })
}