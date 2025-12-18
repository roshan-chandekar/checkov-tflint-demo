output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.table.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.table.arn
}

output "table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.table.id
}

