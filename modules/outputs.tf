output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3_bucket.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_bucket.bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb_table.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_table.table_arn
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  value       = module.kinesis_stream.stream_name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream"
  value       = module.kinesis_stream.stream_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.function_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.lambda_iam_role.role_arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.secrets_manager.secret_arn
}

output "secrets_manager_secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = module.secrets_manager.secret_name
}

output "kms_key_arns" {
  description = "ARNs of all KMS keys"
  value = {
    s3_kms       = module.kms_s3.key_arn
    dynamodb_kms = module.kms_dynamodb.key_arn
    kinesis_kms  = module.kms_kinesis.key_arn
    secrets_kms  = module.kms_secrets.key_arn
  }
}

