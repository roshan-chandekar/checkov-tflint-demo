resource "aws_iam_role" "role" {
  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = var.assume_role_policy
  max_session_duration = var.max_session_duration

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

resource "aws_iam_policy" "policy" {
  count       = var.policy_document != null ? 1 : 0
  name        = var.policy_name != null ? var.policy_name : "${var.role_name}-policy"
  description = var.policy_description
  policy      = var.policy_document

  tags = merge(var.tags, {
    Name = var.policy_name != null ? var.policy_name : "${var.role_name}-policy"
  })
}

resource "aws_iam_role_policy_attachment" "policy" {
  count      = var.policy_document != null ? 1 : 0
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy[0].arn
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.role.name
  policy_arn = each.value
}

