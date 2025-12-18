output "key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.key.key_id
}

output "key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.key.arn
}

output "alias_arn" {
  description = "KMS alias ARN"
  value       = var.alias != null ? aws_kms_alias.key[0].arn : null
}

