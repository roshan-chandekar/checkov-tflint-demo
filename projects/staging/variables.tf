variable "project_name" {
  description = "Project name"
  type        = string
  default     = "checkov-tflint-demo"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project     = "checkov-tflint-demo"
    Project = "staging"
    ManagedBy   = "terraform"
  }
}

