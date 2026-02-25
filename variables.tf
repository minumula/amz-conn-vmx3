variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "connect_instance_alias" {
  description = "Amazon Connect instance alias (lowercase)"
  type        = string
}

variable "connect_instance_arn" {
  description = "Amazon Connect instance ARN"
  type        = string
}

variable "connect_recordings_bucket_arn" {
  description = "ARN of the S3 bucket used for Connect recordings"
  type        = string
}

variable "connect_ctr_stream_arn" {
  description = "ARN of the Kinesis Data Stream for CTR streaming"
  type        = string
}

variable "recordings_expire_days" {
  description = "Days before recordings are lifecycled"
  type        = number
  default     = 7
}

variable "expired_recording_behavior" {
  description = "Action when recordings expire: delete, keep, or glacier"
  type        = string
  default     = "delete"
  validation {
    condition     = contains(["delete", "keep", "glacier"], var.expired_recording_behavior)
    error_message = "Must be delete, keep, or glacier"
  }
}

variable "enable_bucket_versioning" {
  description = "Enable S3 versioning on buckets"
  type        = bool
  default     = false
}

variable "lambda_logging_level" {
  description = "Lambda logging level"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["ERROR", "WARN", "INFO", "DEBUG"], var.lambda_logging_level)
    error_message = "Must be ERROR, WARN, INFO, or DEBUG"
  }
}

variable "package_version" {
  description = "VMX3 package version"
  type        = string
  default     = "2025.09.13"
}

variable "url_expire_days" {
  description = "Days before presigned URL expires"
  type        = number
  default     = 7
  validation {
    condition     = var.url_expire_days >= 1 && var.url_expire_days <= 7
    error_message = "URL expiration must be between 1 and 7 days"
  }
}
