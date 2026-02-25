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
