# Architecture Overview

## Project Structure

This project follows a production-grade Terraform structure with clear separation of concerns:

### Modules Directory (`modules/`)

Contains reusable Terraform modules for each AWS resource type:

- **kms/**: KMS key module with policy support
- **s3/**: S3 bucket module with encryption and versioning
- **dynamodb/**: DynamoDB table module with encryption
- **kinesis/**: Kinesis stream module with encryption
- **lambda/**: Lambda function module with CloudWatch Logs
- **secrets-manager/**: Secrets Manager module with encryption
- **iam/**: IAM role and policy module

The `modules/main.tf` file orchestrates all modules to create a complete infrastructure stack.

### Projects Directory (`projects/`)

Contains project-specific configurations:

- **dev/**: Development project (1 Kinesis shard)
- **staging/**: Staging project (2 Kinesis shards)
- **prod/**: Production project (3 Kinesis shards)

Each project:
- References the root module from `modules/`
- Has its own `terraform.tfvars` for configuration
- Can be deployed independently

### Scripts Directory (`scripts/`)

Contains helper scripts:
- `lambda_function.py`: Lambda function source code
- `build_lambda.sh`: Script to build Lambda deployment package

## Resource Dependencies

```
KMS Keys (4 keys)
├── S3 KMS Key
│   └── Used by: S3 Bucket
├── DynamoDB KMS Key
│   └── Used by: DynamoDB Table
├── Kinesis KMS Key
│   └── Used by: Kinesis Stream
└── Secrets Manager KMS Key
    └── Used by: Secrets Manager Secret

IAM Role
└── Lambda Function
    ├── Accesses: S3 Bucket
    ├── Accesses: DynamoDB Table
    ├── Accesses: Kinesis Stream
    └── Accesses: Secrets Manager Secret
```

## Security Architecture

### Encryption

- **At Rest**: All resources encrypted with KMS keys
- **In Transit**: S3 bucket policy enforces HTTPS
- **Key Rotation**: All KMS keys have rotation enabled

### Access Control

- **IAM**: Least-privilege policies for Lambda
- **S3**: Public access blocked, HTTPS-only policy
- **KMS**: Service-specific key policies

### Monitoring

- **CloudWatch Logs**: Lambda function logs
- **DynamoDB**: Point-in-time recovery enabled
- **S3**: Versioning enabled

## Deployment Flow

1. **Build Lambda Package**: `scripts/build_lambda.sh`
2. **Initialize Terraform**: `terraform init` in project directory
3. **Plan**: `terraform plan` to review changes
4. **Apply**: `terraform apply` to deploy
5. **Verify**: Check outputs and test resources

## CI/CD Pipeline

The Jenkins pipeline:
1. Builds Lambda package
2. Runs security scans (Checkov, TFLint)
3. Validates Terraform configuration
4. Creates and validates plan
5. Optionally applies changes

## Best Practices Implemented

- ✅ Modular architecture
- ✅ Project separation
- ✅ Version pinning
- ✅ Resource tagging
- ✅ Encryption everywhere
- ✅ Least-privilege IAM
- ✅ Security scanning
- ✅ CI/CD automation

