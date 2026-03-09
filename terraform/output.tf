output "card_request_queue_url" {
  value = aws_sqs_queue.create_request_card_sqs.url
}

output "purchase_endpoint" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/purchase"
}

output "transaction_endpoint" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/transactions/save/{card_id}"
}

output "card_activate_endpoint" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/card/activate"
}