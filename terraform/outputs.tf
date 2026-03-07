output "transaction_endpoint" {
  value = "${aws_api_gateway_stage.transaction_stage.invoke_url}/transactions/save/{card_id}"
}