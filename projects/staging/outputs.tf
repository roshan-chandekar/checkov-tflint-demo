output "s3_bucket_id" {
  value = module.infrastructure.s3_bucket_id
}

output "dynamodb_table_name" {
  value = module.infrastructure.dynamodb_table_name
}

output "kinesis_stream_name" {
  value = module.infrastructure.kinesis_stream_name
}

output "lambda_function_arn" {
  value = module.infrastructure.lambda_function_arn
}

output "secrets_manager_secret_arn" {
  value = module.infrastructure.secrets_manager_secret_arn
}

