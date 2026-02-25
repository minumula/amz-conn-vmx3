output "recordings_bucket_name" {
  description = "VMX3 recordings bucket name"
  value       = module.storage.recordings_bucket_name
}

output "transcripts_bucket_name" {
  description = "VMX3 transcripts bucket name"
  value       = module.storage.transcripts_bucket_name
}

output "recording_processor_function_name" {
  description = "Recording processor Lambda function name"
  value       = module.lambda.recording_processor_function_name
}

output "transcriber_function_arn" {
  description = "Transcriber Lambda function ARN"
  value       = module.lambda.transcriber_function_arn
}

output "packager_function_arn" {
  description = "Packager Lambda function ARN"
  value       = module.lambda.packager_function_arn
}

output "timestamper_function_arn" {
  description = "Timestamper Lambda function ARN"
  value       = module.lambda.timestamper_function_arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for voicemail notifications"
  value       = module.storage.sns_topic_arn
}
