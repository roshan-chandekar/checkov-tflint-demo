resource "aws_kms_key" "key" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation

  policy = var.policy != null ? var.policy : jsonencode({
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_kms_alias" "key" {
  count         = var.alias != null ? 1 : 0
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.key.key_id
}

data "aws_caller_identity" "current" {}

