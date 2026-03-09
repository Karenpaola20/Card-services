resource "aws_iam_role" "card_lambda_role" {
  name = "card-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]

  })
}

resource "aws_iam_role_policy" "card_lambda_policy" {
  name = "card-lambda-policy"
  role = aws_iam_role.card_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "dynamodb:Query",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:PutItem",
                "dynamodb:Scan"
            ]
            Resource = [
                aws_dynamodb_table.card_table.arn,
                "${aws_dynamodb_table.card_table.arn}/*",
                aws_dynamodb_table.transaction_table.arn,
                "${aws_dynamodb_table.transaction_table.arn}/*",
                "${aws_dynamodb_table.transaction_table.arn}/index/*"
            ]
        },
        {
            Effect = "Allow"
            Action = [
                "s3:PutObject",
                "s3:GetObject"
            ]
            Resource = "${aws_s3_bucket.transactions_report_bucket.arn}/*"
        },
        {
            Effect = "Allow"
            Action = [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:SendMessage"
            ]
            Resource = aws_sqs_queue.create_request_card_sqs.arn
        },
        {
            Effect = "Allow"
            Action = [
                "sqs:SendMessage"
            ]
            Resource = "arn:aws:sqs:us-east-1:537236557851:notification-email-sqs"
        },
        {
            Effect = "Allow"
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
            Resource = "*"
        }
    ]
  })
}