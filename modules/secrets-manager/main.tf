resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  description             = var.description
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id

  tags = merge(var.tags, {
    Name = var.secret_name
  })
}

resource "aws_secretsmanager_secret_version" "secret" {
  count         = var.secret_string != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = var.secret_string
}

