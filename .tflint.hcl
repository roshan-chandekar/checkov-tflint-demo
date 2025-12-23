config {
  format = "compact"
  # FIXED: module = true is replaced by the line below for v0.54.0+
  call_module_type = "all"
  plugin_dir       = "~/.tflint.d/plugins"
}

plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# --- Core Terraform Rules ---

rule "terraform_deprecated_interpolation" { enabled = true }
rule "terraform_deprecated_index"         { enabled = true }
rule "terraform_unused_declarations"      { enabled = true }
rule "terraform_comment_syntax"           { enabled = true }
rule "terraform_documented_outputs"       { enabled = true }
rule "terraform_documented_variables"     { enabled = true }
rule "terraform_typed_variables"          { enabled = true }
rule "terraform_module_pinned_source"     { enabled = true }
rule "terraform_naming_convention"        { enabled = true }
rule "terraform_required_version"         { enabled = true }
rule "terraform_required_providers"        { enabled = true }
rule "terraform_standard_module_structure" { enabled = true }

# --- AWS Specific Rules ---

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Project", "Environment", "ManagedBy"]
}
