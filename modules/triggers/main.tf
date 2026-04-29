# Kinesis Event Source Mapping for Recording Processor
resource "aws_lambda_event_source_mapping" "ctr_stream" {
  batch_size        = 1
  bisect_batch_on_function_error = true
  enabled = true
  event_source_arn  = var.connect_ctr_stream_arn
  function_name     = var.recording_processor_function_arn
  maximum_retry_attempts = 3
  starting_position = "LATEST"
  filter_criteria {
    filter {
      pattern = jsonencode({
        data = {
          Attributes = {
            vmx3_flag = ["1"]           # VMX3 flag indicates voicemail eligibility
          }
          Recordings = {
            ParticipantType = ["IVR"]   # Only IVR recordings (customer side)
          }
          Agent = [null]                # No agent assigned (unanswered call)
        }
      })
    }
  }
}

# EventBridge Rule for Transcriber (S3 recordings bucket)
resource "aws_cloudwatch_event_rule" "transcriber" {
  name        = "VMX3-TranscriberRule"
  description = "Trigger transcriber when recording is created"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.recordings_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "transcriber" {
  rule      = aws_cloudwatch_event_rule.transcriber.name
  target_id = "${var.connect_instance_alias}-TranscriberFunction"
  arn       = var.transcriber_function_arn
}

resource "aws_lambda_permission" "transcriber" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.transcriber_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.transcriber.arn
}

# EventBridge Rule for Packager (S3 transcripts bucket)
resource "aws_cloudwatch_event_rule" "packager" {
  # name        = "${var.connect_instance_alias}-PackagerRule"
  name        = "VMX3-PackagerRule"
  description = "Trigger packager when transcript is created"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.transcripts_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "packager" {
  rule      = aws_cloudwatch_event_rule.packager.name
  target_id = "${var.connect_instance_alias}-PackagerFunction"
  arn       = var.packager_function_arn
}

resource "aws_lambda_permission" "packager" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.packager_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.packager.arn
}

# EventBridge Rule for Transcribe Error Handler
resource "aws_cloudwatch_event_rule" "transcribe_error" {
  # name        = "${var.connect_instance_alias}-TranscribeErrorRule"
  name        = "VMX3-TranscribeErrorRule"
  description = "Trigger error handler when transcribe job fails"

  event_pattern = jsonencode({
    source      = ["aws.transcribe"]
    detail-type = ["Transcribe Job State Change"]
    detail = {
      TranscriptionJobName = [{
        prefix = "vmx3_"
      }]
      TranscriptionJobStatus = ["FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "transcribe_error" {
  rule      = aws_cloudwatch_event_rule.transcribe_error.name
  target_id = "${var.connect_instance_alias}-TranscribeErrorFunction"
  arn       = var.transcribe_error_handler_function_arn
}

resource "aws_lambda_permission" "transcribe_error" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.transcribe_error_handler_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.transcribe_error.arn
}

# Connect Integration for Timestamper
resource "aws_connect_lambda_function_association" "timestamper" {
  instance_id  = var.connect_instance_id
  function_arn = var.timestamper_function_arn
}
