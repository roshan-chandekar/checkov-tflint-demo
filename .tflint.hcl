config {
  call_module_type = "local"
  force = false
}

plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["Project", "Environment", "ManagedBy"]
}

rule "aws_iam_policy_document_gov_friendly" {
  enabled = true
}

# Note: aws_iam_policy_gov_friendly rule does not exist in tflint-ruleset-aws
# Removed to prevent TFLint config errors

