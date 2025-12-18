variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Assume role policy JSON"
  type        = string
}

variable "policy_document" {
  description = "Policy document JSON (optional)"
  type        = string
  default     = null
}

variable "policy_name" {
  description = "Name of the policy (optional)"
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Description of the policy"
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags for the IAM role"
  type        = map(string)
  default     = {}
}

