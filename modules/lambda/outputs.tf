output "recording_processor_function_name" {
  value = aws_lambda_function.recording_processor.function_name
}

output "recording_processor_function_arn" {
  value = aws_lambda_function.recording_processor.arn
}

output "transcriber_function_arn" {
  value = aws_lambda_function.transcriber.arn
}

output "packager_function_arn" {
  value = aws_lambda_function.packager.arn
}

output "timestamper_function_arn" {
  value = aws_lambda_function.timestamper.arn
}

output "presigner_function_arn" {
  value = aws_lambda_function.presigner.arn
}

output "transcribe_error_handler_function_arn" {
  value = aws_lambda_function.transcribe_error_handler.arn
}
