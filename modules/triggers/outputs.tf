output "transcriber_rule_arn" {
  value = aws_cloudwatch_event_rule.transcriber.arn
}

output "packager_rule_arn" {
  value = aws_cloudwatch_event_rule.packager.arn
}

output "kinesis_mapping_uuid" {
  value = aws_lambda_event_source_mapping.ctr_stream.uuid
}
