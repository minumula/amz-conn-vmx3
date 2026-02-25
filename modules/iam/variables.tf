variable "connect_instance_alias" {
  description = "Connect instance alias"
  type        = string
}

variable "connect_instance_arn" {
  description = "Connect instance ARN"
  type        = string
}

variable "connect_recordings_bucket_arn" {
  description = "Connect recordings bucket ARN"
  type        = string
}

variable "connect_ctr_stream_arn" {
  description = "Kinesis CTR stream ARN"
  type        = string
}

variable "recordings_bucket_arn" {
  description = "VMX3 recordings bucket ARN"
  type        = string
}

variable "transcripts_bucket_arn" {
  description = "VMX3 transcripts bucket ARN"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}
