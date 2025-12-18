variable "stream_name" {
  description = "Name of the Kinesis stream"
  type        = string
}

variable "shard_count" {
  description = "Number of shards"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Retention period in hours"
  type        = number
  default     = 24
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "shard_level_metrics" {
  description = "List of shard-level metrics"
  type        = list(string)
  default     = ["IncomingRecords", "OutgoingRecords"]
}

variable "tags" {
  description = "Tags for the Kinesis stream"
  type        = map(string)
  default     = {}
}

