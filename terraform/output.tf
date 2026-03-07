output "card_request_queue_url" {
  value = aws_sqs_queue.create_request_card_sqs.url
}