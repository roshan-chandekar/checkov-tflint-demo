output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.bucket.bucket_domain_name
}

