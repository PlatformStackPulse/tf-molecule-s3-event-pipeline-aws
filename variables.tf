# --- Core ---
variable "force_destroy" {
  type        = bool
  default     = false
  description = "Allow destruction of non-empty bucket (use only in dev/test)"
}

# --- Encryption ---
variable "sse_algorithm" {
  type        = string
  default     = "aws:kms"
  description = "Server-side encryption algorithm (AES256 or aws:kms). Defaults to KMS for pipeline data."
  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS key ARN for encryption (uses AWS-managed key if null)"
}

variable "bucket_key_enabled" {
  type        = bool
  default     = true
  description = "Enable S3 Bucket Key to reduce KMS costs"
}

# --- Versioning ---
variable "versioning_status" {
  type        = string
  default     = "Enabled"
  description = "Versioning status (Enabled/Suspended). Enabled by default for data lineage."
  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.versioning_status)
    error_message = "versioning_status must be Enabled, Suspended, or Disabled."
  }
}

# --- Bucket Policy ---
variable "bucket_policy" {
  type        = string
  description = "JSON-encoded IAM policy document for bucket access (e.g. cross-account write, service principal access)"
  validation {
    condition     = can(jsondecode(var.bucket_policy))
    error_message = "bucket_policy must be valid JSON."
  }
}

# --- Notifications (core — this is the molecule's primary purpose) ---
variable "lambda_notifications" {
  type = list(object({
    id                  = optional(string, null)
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string, null)
    filter_suffix       = optional(string, null)
  }))
  default     = []
  description = "Lambda function notification configurations for event-driven processing"
}

variable "sns_notifications" {
  type = list(object({
    id            = optional(string, null)
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string, null)
    filter_suffix = optional(string, null)
  }))
  default     = []
  description = "SNS topic notification configurations for fan-out processing"
}

variable "sqs_notifications" {
  type = list(object({
    id            = optional(string, null)
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string, null)
    filter_suffix = optional(string, null)
  }))
  default     = []
  description = "SQS queue notification configurations for decoupled processing"
}

# --- Lifecycle (optional) ---
variable "enable_lifecycle" {
  type        = bool
  default     = false
  description = "Enable lifecycle rules for archiving/expiring processed data"
}

variable "lifecycle_rules" {
  type = list(object({
    id                                 = string
    status                             = optional(string, "Enabled")
    prefix                             = optional(string, "")
    expiration_days                    = optional(number, null)
    noncurrent_version_expiration_days = optional(number, null)
    transition = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default     = []
  description = "Lifecycle rules for processed data (e.g. move to Glacier after 30d, expire after 90d)"
}
