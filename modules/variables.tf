variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "project" {
  description = "Project name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "demo-table"
}

variable "kinesis_stream_name" {
  description = "Name of the Kinesis stream"
  type        = string
  default     = "stream"
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 1
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "demo-lambda"
}

variable "lambda_filename" {
  description = "Path to Lambda deployment package"
  type        = string
}

variable "secret_name" {
  description = "Name of the Secrets Manager secret"
  type        = string
  default     = "demo-secret"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

