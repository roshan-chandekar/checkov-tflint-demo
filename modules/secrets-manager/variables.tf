variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = ""
}

variable "recovery_window_in_days" {
  description = "Recovery window in days"
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "secret_string" {
  description = "Secret string value (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the secret"
  type        = map(string)
  default     = {}
}

