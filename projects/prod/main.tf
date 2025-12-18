module "infrastructure" {
  source = "../../modules"

  project_name = var.project_name
  project      = "prod"
  aws_region   = var.aws_region

  # S3 Configuration
  s3_bucket_name      = "${var.project_name}-prod-${data.aws_caller_identity.current.account_id}"
  s3_enable_versioning = true

  # DynamoDB Configuration
  dynamodb_table_name = "demo-table"

  # Kinesis Configuration
  kinesis_stream_name = "${var.project_name}-stream"
  kinesis_shard_count = 3

  # Lambda Configuration
  lambda_function_name = "demo-lambda"
  lambda_filename      = "../../scripts/lambda_function.zip"

  # Secrets Manager Configuration
  secret_name = "demo-secret"

  tags = var.tags
}

data "aws_caller_identity" "current" {}

