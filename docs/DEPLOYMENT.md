# Deployment Guide

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Python 3.x for Lambda function
4. Checkov and TFLint for security scanning (optional but recommended)

## Initial Setup

### 1. Build Lambda Package

```bash
cd scripts
chmod +x build_lambda.sh
./build_lambda.sh
cd ..
```

This creates `scripts/lambda_function.zip` which is required for Lambda deployment.

### 2. Configure Project

Navigate to your desired project directory:

```bash
cd projects/dev    # or staging, or prod
```

Review and customize `terraform.tfvars` if needed.

## Deployment Steps

### Development Project

```bash
cd projects/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply
```

### Staging Project

```bash
cd projects/staging

terraform init
terraform plan
terraform apply
```

### Production Project

```bash
cd projects/prod

terraform init
terraform plan

# Review carefully before applying to production
terraform apply
```

## Verification

After deployment, verify resources:

```bash
# Check outputs
terraform output

# Verify S3 bucket
aws s3 ls | grep <bucket-name>

# Verify DynamoDB table
aws dynamodb list-tables

# Verify Lambda function
aws lambda list-functions | grep <function-name>

# Verify Kinesis stream
aws kinesis list-streams
```

## Security Scanning

### Before Deployment

```bash
# Run TFLint
cd projects/dev
tflint --init
tflint

# Run Checkov
checkov -d . --framework terraform

# Run Terraform validate
terraform validate
```

### After Planning

```bash
# Create plan
terraform plan -out=tfplan

# Convert to JSON
terraform show -json tfplan > tfplan.json

# Scan plan
checkov -f tfplan.json --framework terraform_plan
```

## Cleanup

To destroy all resources:

```bash
cd projects/dev  # or staging, or prod
terraform destroy
```

**Warning**: This will delete all resources including data. Ensure you have backups if needed.

## Troubleshooting

### Module Not Found

If you see "module not found" errors:

```bash
# Re-initialize Terraform
terraform init -upgrade
```

### Lambda Package Missing

If Lambda deployment fails:

```bash
# Rebuild the package
cd scripts
./build_lambda.sh
cd ../projects/dev
terraform apply
```

### KMS Key Policy Errors

If you encounter KMS policy errors:

1. Verify your AWS account ID matches the policy
2. Check that service principals are correct
3. Ensure you have permissions to create KMS keys

### State Lock Issues

If Terraform state is locked:

```bash
# Check for locks
terraform force-unlock <lock-id>
```

Use with caution and only if you're sure no other operations are running.

## CI/CD Deployment

The Jenkins pipeline automates all these steps:

1. Select project parameter (dev/staging/prod)
2. Pipeline will:
   - Build Lambda package
   - Run security scans
   - Validate configuration
   - Create plan
   - Optionally apply (on main/master branches)

## Best Practices

1. **Always review the plan** before applying
2. **Use separate AWS accounts** for different projects
3. **Enable MFA** for production deployments
4. **Review security scan results** before applying
5. **Test in dev/staging** before production
6. **Keep state files secure** (use remote state in production)
7. **Tag resources properly** for cost tracking
8. **Monitor CloudWatch** after deployment

