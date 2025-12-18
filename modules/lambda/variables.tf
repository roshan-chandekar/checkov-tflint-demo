variable "filename" {
  description = "Path to the deployment package"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string
}

variable "handler" {
  description = "Function entrypoint"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Function memory size in MB"
  type        = number
  default     = 128
}

variable "source_code_hash" {
  description = "Source code hash (optional)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = null
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags for the Lambda function"
  type        = map(string)
  default     = {}
}

