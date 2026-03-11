variable "connect_instance_alias" {
  description = "Connect instance alias"
  type        = string
}

variable "connect_instance_arn" {
  description = "Connect instance ARN"
  type        = string
}

variable "connect_ctr_stream_arn" {
  description = "Kinesis CTR stream ARN"
  type        = string
}

variable "recordings_bucket_name" {
  description = "Recordings bucket name"
  type        = string
}

variable "recordings_bucket_arn" {
  description = "Recordings bucket ARN"
  type        = string
}

variable "transcripts_bucket_name" {
  description = "Transcripts bucket name"
  type        = string
}

variable "transcripts_bucket_arn" {
  description = "Transcripts bucket ARN"
  type        = string
}

variable "recording_processor_function_name" {
  description = "Recording processor function name"
  type        = string
}

variable "recording_processor_function_arn" {
  description = "Recording processor function arn"
  type        = string
}

variable "transcriber_function_arn" {
  description = "Transcriber function ARN"
  type        = string
}

variable "packager_function_arn" {
  description = "Packager function ARN"
  type        = string
}

variable "timestamper_function_arn" {
  description = "Timestamper function ARN"
  type        = string
}

variable "transcribe_error_handler_function_arn" {
  description = "Transcribe error handler function ARN"
  type        = string
}

variable "connect_instance_id" {
  description = "Connect instance ID"
  type        = string
}
