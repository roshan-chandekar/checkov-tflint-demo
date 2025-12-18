# Checkov and TFLint Demo - Production-Grade AWS Terraform Project

This is a production-grade Terraform project demonstrating AWS infrastructure setup with security scanning using Checkov and linting using TFLint. The project follows best practices with modular architecture, project separation, and comprehensive security policies.

## Project Structure

```
.
├── modules/                    # Reusable Terraform modules
│   ├── s3/                    # S3 bucket module
│   ├── dynamodb/              # DynamoDB table module
│   ├── kinesis/               # Kinesis stream module
│   ├── kms/                   # KMS key module
│   ├── lambda/                # Lambda function module
│   ├── secrets-manager/       # Secrets Manager module
│   ├── iam/                   # IAM role and policy module
│   ├── main.tf                # Root module orchestrating all resources
│   ├── variables.tf           # Root module variables
│   └── outputs.tf             # Root module outputs
├── projects/                  # Project-specific configurations
│   ├── dev/                   # Development project
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/               # Staging project
│   └── prod/                  # Production project
├── scripts/                   # Helper scripts
│   ├── lambda_function.py     # Lambda function source code
│   └── build_lambda.sh        # Script to build Lambda package
├── docs/                      # Documentation
├── Jenkinsfile                # CI/CD pipeline configuration
├── versions.tf                # Terraform and provider versions
├── .tflint.hcl                # TFLint configuration
├── .checkov.yaml              # Checkov configuration
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## Resources Created

This Terraform configuration creates the following AWS resources:

1. **S3 Bucket**
   - Server-side encryption with KMS
   - Versioning enabled
   - Public access blocked
   - Bucket policy enforcing HTTPS

2. **DynamoDB Table**
   - Pay-per-request billing mode
   - KMS encryption
   - Point-in-time recovery enabled

3. **Kinesis Stream**
   - KMS encryption
   - Configurable shard count per environment
   - Shard-level metrics enabled

4. **KMS Keys** (4 separate keys)
   - S3 encryption key
   - DynamoDB encryption key
   - Kinesis encryption key
   - Secrets Manager encryption key
   - All with key rotation enabled

5. **Lambda Function**
   - Python 3.11 runtime
   - IAM role with least-privilege policies
   - Access to S3, DynamoDB, Kinesis, and Secrets Manager
   - CloudWatch Logs integration

6. **Secrets Manager**
   - Encrypted secret storage
   - KMS encryption

7. **IAM Roles and Policies**
   - Lambda execution role
   - Least-privilege policies for all services

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Python 3.x (for Lambda function)
- Checkov (for security scanning)
- TFLint (for linting)
- Jenkins (for CI/CD pipeline)

## Quick Start

### 1. Build Lambda Package

```bash
cd scripts
./build_lambda.sh
cd ..
```

### 2. Deploy to Development Project

```bash
cd projects/dev
terraform init
terraform plan
terraform apply
```

### 3. Deploy to Other Projects

```bash
# Staging
cd projects/staging
terraform init
terraform plan
terraform apply

# Production
cd projects/prod
terraform init
terraform plan
terraform apply
```

## Module Usage

Each module is self-contained and reusable. Example usage:

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name      = "my-bucket-name"
  enable_versioning = true
  kms_key_id       = module.kms_key.key_arn

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

## Project Configuration

Each project has its own configuration in `projects/{project}/terraform.tfvars`:

- **dev**: 1 Kinesis shard, development settings
- **staging**: 2 Kinesis shards, staging settings
- **prod**: 3 Kinesis shards, production settings

Customize these files based on your requirements.

## Security Scanning

### Using Checkov

Run Checkov to scan for security misconfigurations:

```bash
# Scan modules
checkov -d modules --framework terraform

# Scan specific project
checkov -d projects/dev --framework terraform

# Scan with plan file
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
checkov -f tfplan.json --framework terraform_plan
```

### Using TFLint

Run TFLint to check for Terraform best practices:

```bash
# Initialize TFLint
tflint --init

# Lint modules
cd modules/s3
tflint

# Lint project
cd projects/dev
tflint
```

## Jenkins Pipeline

⚠️ **IMPORTANT: This pipeline is configured for TESTING ONLY - No infrastructure will be created!**

The included `Jenkinsfile` sets up a validation and security scanning pipeline that:

1. Checks out the code
2. Installs Terraform, Checkov, and TFLint
3. Builds Lambda deployment package (for validation)
4. Runs `terraform fmt` to check formatting
5. Runs TFLint on modules and project
6. Runs Checkov security scans on modules and project
7. Runs `terraform init` and `terraform validate`
8. Creates a Terraform plan (for validation only)
9. Runs Checkov on the plan
10. **Does NOT run `terraform apply`** - Infrastructure creation is disabled

### Pipeline Parameters

- **PROJECT**: Select which project to test (dev, staging, prod)

### Using the Pipeline

1. Create a new Jenkins pipeline job
2. Point it to your repository
3. **AWS credentials are NOT required** (only validation runs, no resources created)
4. Select the project parameter
5. Run the pipeline to see Checkov and TFLint results

### To Actually Deploy Infrastructure

If you want to deploy infrastructure, run Terraform manually:

```bash
cd projects/dev  # or staging, or prod
terraform init
terraform plan
terraform apply  # Only when ready to create resources
```

See `.pipeline-note.md` for more details.

## Module Documentation

### S3 Module

Creates an S3 bucket with encryption, versioning, and security policies.

**Variables:**
- `bucket_name` (required): Name of the bucket
- `enable_versioning` (optional): Enable versioning (default: true)
- `kms_key_id` (optional): KMS key for encryption
- `bucket_policy` (optional): Custom bucket policy JSON
- `tags` (optional): Resource tags

### DynamoDB Module

Creates a DynamoDB table with encryption and point-in-time recovery.

**Variables:**
- `table_name` (required): Name of the table
- `billing_mode` (optional): PAY_PER_REQUEST or PROVISIONED
- `hash_key` (required): Hash key attribute name
- `attributes` (required): List of attribute definitions
- `kms_key_arn` (optional): KMS key ARN for encryption
- `tags` (optional): Resource tags

### Kinesis Module

Creates a Kinesis stream with encryption.

**Variables:**
- `stream_name` (required): Name of the stream
- `shard_count` (optional): Number of shards (default: 1)
- `kms_key_id` (optional): KMS key for encryption
- `tags` (optional): Resource tags

### KMS Module

Creates a KMS key with optional alias.

**Variables:**
- `name` (required): Name of the key
- `description` (required): Description
- `alias` (optional): Key alias
- `policy` (optional): Custom key policy
- `tags` (optional): Resource tags

### Lambda Module

Creates a Lambda function with CloudWatch Logs.

**Variables:**
- `filename` (required): Path to deployment package
- `function_name` (required): Function name
- `role_arn` (required): IAM role ARN
- `handler` (required): Function handler
- `runtime` (optional): Runtime (default: python3.11)
- `tags` (optional): Resource tags

### Secrets Manager Module

Creates a Secrets Manager secret with encryption.

**Variables:**
- `secret_name` (required): Name of the secret
- `kms_key_id` (optional): KMS key for encryption
- `secret_string` (optional): Secret value
- `tags` (optional): Resource tags

### IAM Module

Creates an IAM role with policies.

**Variables:**
- `role_name` (required): Role name
- `assume_role_policy` (required): Assume role policy JSON
- `policy_document` (optional): Inline policy document
- `tags` (optional): Resource tags

## Security Features

- **Encryption at Rest**: All resources use KMS encryption
- **Encryption in Transit**: S3 bucket policy enforces HTTPS
- **Least Privilege**: IAM policies follow least-privilege principles
- **Public Access Blocked**: S3 bucket has public access blocked
- **Key Rotation**: All KMS keys have rotation enabled
- **Logging**: CloudWatch Logs enabled for Lambda
- **Point-in-Time Recovery**: Enabled for DynamoDB

## Best Practices

This project follows Terraform and AWS best practices:

- ✅ Modular architecture for reusability
- ✅ Project separation (dev/staging/prod)
- ✅ Version pinning for providers
- ✅ Resource tagging
- ✅ Encryption at rest and in transit
- ✅ Least-privilege IAM policies
- ✅ Public access restrictions
- ✅ Versioning for S3
- ✅ Point-in-time recovery for DynamoDB
- ✅ Security scanning integration
- ✅ CI/CD pipeline automation

## Troubleshooting

### Lambda Function Not Found

If you get an error about `lambda_function.zip` not found:

1. Build the package: `cd scripts && ./build_lambda.sh`
2. Ensure the path in project configuration is correct

### Module Source Errors

If Terraform can't find modules:

1. Ensure you're running `terraform init` in the project directory
2. Check that module paths are relative to the project directory

### KMS Key Policy Errors

If you encounter KMS key policy errors:

1. Ensure your AWS account ID is correct
2. Verify service principals are properly configured
3. Check that key policies allow necessary services

### Checkov Failures

Some Checkov checks may fail. Review the output and:

1. Fix critical security issues
2. Suppress false positives using Checkov skip comments if needed
3. Update policies to meet your organization's requirements

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is provided as-is for demonstration purposes.
