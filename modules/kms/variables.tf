variable "name" {
  description = "Name of the KMS key"
  type        = string
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Deletion window in days"
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "Enable key rotation"
  type        = bool
  default     = true
}

variable "alias" {
  description = "KMS key alias (optional)"
  type        = string
  default     = null
}

variable "policy" {
  description = "KMS key policy (optional, will use default if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the KMS key"
  type        = map(string)
  default     = {}
}

