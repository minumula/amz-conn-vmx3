variable "connect_instance_alias" {
  description = "Connect instance alias"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "package_version" {
  description = "Package version"
  type        = string
}

variable "lambda_logging_level" {
  description = "Lambda logging level"
  type        = string
}

variable "recordings_bucket_name" {
  description = "Recordings bucket name"
  type        = string
}

variable "transcripts_bucket_name" {
  description = "Transcripts bucket name"
  type        = string
}

variable "recording_processor_role_arn" {
  description = "Recording processor IAM role ARN"
  type        = string
}

variable "transcriber_role_arn" {
  description = "Transcriber IAM role ARN"
  type        = string
}

variable "packager_role_arn" {
  description = "Packager IAM role ARN"
  type        = string
}

variable "timestamper_role_arn" {
  description = "Timestamper IAM role ARN"
  type        = string
}

variable "presigner_role_arn" {
  description = "Presigner IAM role ARN"
  type        = string
}

variable "transcribe_error_handler_role_arn" {
  description = "Transcribe error handler IAM role ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for voicemail notifications"
  type        = string
}

variable "url_expire_days" {
  description = "Days before presigned URL expires"
  type        = number
  default     = 7
}
