variable "connect_instance_id" {
  description = "Connect instance id"
  type        = string
}

variable "connect_instance_alias" {
  description = "Connect instance alias"
  type        = string
}

variable "recordings_expire_days" {
  description = "Days before recordings expire"
  type        = number
}

variable "expired_recording_behavior" {
  description = "Behavior when recordings expire"
  type        = string
}

variable "enable_bucket_versioning" {
  description = "Enable bucket versioning"
  type        = bool
}

variable "s3_connect_lifecycle_abort_incomplete_multipart_upload_days_prd" {
  description = "Abort incomplete multipart upload number of days after initiation."
  type        = number
  default     = 1
}
