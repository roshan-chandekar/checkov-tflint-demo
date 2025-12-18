output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.role.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.role.name
}

output "policy_arn" {
  description = "IAM policy ARN (if created)"
  value       = var.policy_document != null ? aws_iam_policy.policy[0].arn : null
}

