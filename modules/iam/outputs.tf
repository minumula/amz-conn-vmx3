output "recording_processor_role_arn" {
  value = aws_iam_role.recording_processor.arn
}

output "transcriber_role_arn" {
  value = aws_iam_role.transcriber.arn
}

output "packager_role_arn" {
  value = aws_iam_role.packager.arn
}

output "timestamper_role_arn" {
  value = aws_iam_role.timestamper.arn
}

output "presigner_role_arn" {
  value = aws_iam_role.presigner.arn
}

output "transcribe_error_handler_role_arn" {
  value = aws_iam_role.transcribe_error_handler.arn
}