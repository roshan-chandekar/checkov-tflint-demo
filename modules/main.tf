# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Keys
module "kms_s3" {
  source = "./kms"

  name        = "${var.project_name}-${var.project}-s3-kms"
  description = "KMS key for S3 bucket encryption"
  alias       = "${var.project_name}-${var.project}-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

module "kms_dynamodb" {
  source = "./kms"

  name        = "${var.project_name}-${var.project}-dynamodb-kms"
  description = "KMS key for DynamoDB encryption"
  alias       = "${var.project_name}-${var.project}-dynamodb"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB to use the key"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

module "kms_kinesis" {
  source = "./kms"

  name        = "${var.project_name}-${var.project}-kinesis-kms"
  description = "KMS key for Kinesis stream encryption"
  alias       = "${var.project_name}-${var.project}-kinesis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Kinesis to use the key"
        Effect = "Allow"
        Principal = {
          Service = "kinesis.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "kinesis.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

module "kms_secrets" {
  source = "./kms"

  name        = "${var.project_name}-${var.project}-secrets-kms"
  description = "KMS key for Secrets Manager encryption"
  alias       = "${var.project_name}-${var.project}-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# S3 Bucket
module "s3_bucket" {
  source = "./s3"

  bucket_name      = var.s3_bucket_name
  enable_versioning = var.s3_enable_versioning
  kms_key_id       = module.kms_s3.key_arn

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowSSLRequestsOnly"
        Effect = "Allow"
        Principal = "*"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# DynamoDB Table
module "dynamodb_table" {
  source = "./dynamodb"

  table_name = "${var.project_name}-${var.project}-${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  kms_key_arn                  = module.kms_dynamodb.key_arn
  enable_point_in_time_recovery = true

  tags = var.tags
}

# Kinesis Stream
module "kinesis_stream" {
  source = "./kinesis"

  stream_name     = "${var.project_name}-${var.project}-${var.kinesis_stream_name}"
  shard_count     = var.kinesis_shard_count
  retention_period = 24
  kms_key_id      = module.kms_kinesis.key_arn

  tags = var.tags
}

# Secrets Manager
module "secrets_manager" {
  source = "./secrets-manager"

  secret_name = "${var.project_name}-${var.project}-${var.secret_name}"
  description  = "Demo secret for ${var.project} project"
  kms_key_id   = module.kms_secrets.key_arn

  secret_string = jsonencode({
    username = "demo_user"
    password = "demo_password_123"
  })

  tags = var.tags
}

# IAM Role for Lambda
module "lambda_iam_role" {
  source = "./iam"

  role_name        = "${var.project_name}-${var.project}-lambda-role"
  role_description = "IAM role for Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.project}-${var.lambda_function_name}*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${module.s3_bucket.bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = module.dynamodb_table.table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream"
        ]
        Resource = module.kinesis_stream.stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = module.secrets_manager.secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          module.kms_s3.key_arn,
          module.kms_dynamodb.key_arn,
          module.kms_kinesis.key_arn,
          module.kms_secrets.key_arn
        ]
      }
    ]
  })

  tags = var.tags
}

# Lambda Function
module "lambda_function" {
  source = "./lambda"

  filename      = var.lambda_filename
  function_name = "${var.project_name}-${var.project}-${var.lambda_function_name}"
  role_arn      = module.lambda_iam_role.role_arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  environment_variables = {
    S3_BUCKET_NAME     = module.s3_bucket.bucket_id
    DYNAMODB_TABLE     = module.dynamodb_table.table_name
    KINESIS_STREAM     = module.kinesis_stream.stream_name
    SECRET_NAME        = module.secrets_manager.secret_name
  }

  tags = var.tags
}

