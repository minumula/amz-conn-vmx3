output "recordings_bucket_name" {
  value = aws_s3_bucket.recordings.id
}

output "recordings_bucket_arn" {
  value = aws_s3_bucket.recordings.arn
}

output "transcripts_bucket_name" {
  value = aws_s3_bucket.transcripts.id
}

output "transcripts_bucket_arn" {
  value = aws_s3_bucket.transcripts.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.voicemail.arn
}

output "connect_ctr_stream_arn" {
  value = aws_kinesis_stream.connect_ctr.arn
}
