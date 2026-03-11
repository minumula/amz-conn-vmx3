data "archive_file" "recording_processor" {
  type        = "zip"
  source_file = "${path.module}/functions/recording_processor/lambda_function.py"
  output_path = "${path.module}/builds/recording_processor.zip"
}

data "archive_file" "transcriber" {
  type        = "zip"
  source_file = "${path.module}/functions/transcriber/lambda_function.py"
  output_path = "${path.module}/builds/transcriber.zip"
}

data "archive_file" "packager" {
  type        = "zip"
  source_file = "${path.module}/functions/packager/lambda_function.py"
  output_path = "${path.module}/builds/packager.zip"
}

data "archive_file" "timestamper" {
  type        = "zip"
  source_file = "${path.module}/functions/timestamper/lambda_function.py"
  output_path = "${path.module}/builds/timestamper.zip"
}

data "archive_file" "presigner" {
  type        = "zip"
  source_file = "${path.module}/functions/presigner/lambda_function.py"
  output_path = "${path.module}/builds/presigner.zip"
}

data "archive_file" "transcribe_error_handler" {
  type        = "zip"
  source_file = "${path.module}/functions/transcribe_error_handler/lambda_function.py"
  output_path = "${path.module}/builds/transcribe_error_handler.zip"
}

# Lambda Layer 

# data "archive_file" "python_layer" {
#   type        = "zip"
#   source_dir  = "${path.module}/../../layer/python"
#   output_path = "${path.module}/builds/python_layer.zip"
# }

data "archive_file" "python_layer" {
  type        = "zip"
  source_dir  = "${path.module}/layer/zip/"
  # output_path = "${path.module}/builds/python_layer.zip"
  output_path = "python_layer.zip"
}

resource "aws_lambda_layer_version" "vmx3_python" {
  filename            = data.archive_file.python_layer.output_path
  layer_name          = "VMX3-Python-CommonLayer-${var.connect_instance_alias}"
  compatible_runtimes = ["python3.13"]
  description = "Provides dependencies code and functions for AWS Lambda functions that power Voicemail Express."
  license_info = "https://aws.amazon.com/apache-2-0"
  # source_code_hash    = data.archive_file.python_layer.output_base64sha256
}

# Recording Processor Lambda
resource "aws_lambda_function" "recording_processor" {
  filename         = data.archive_file.recording_processor.output_path
  function_name    = "VMX3-RecordingProcessor-${var.connect_instance_alias}"
  role             = var.recording_processor_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 900
  memory_size      = 512
  source_code_hash = data.archive_file.recording_processor.output_base64sha256
  layers           = [aws_lambda_layer_version.vmx3_python.arn]

  environment {
    variables = {
      aws_region            = var.aws_region
      vmx3_recordings_bucket = var.recordings_bucket_name
      package_version       = var.package_version
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}

# Transcriber Lambda
resource "aws_lambda_function" "transcriber" {
  filename         = data.archive_file.transcriber.output_path
  function_name    = "VMX3-Transcriber-${var.connect_instance_alias}"
  role             = var.transcriber_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 900
  source_code_hash = data.archive_file.transcriber.output_base64sha256

  environment {
    variables = {
      aws_region           = var.aws_region
      s3_transcripts_bucket = var.transcripts_bucket_name
      package_version      = var.package_version
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}

# Packager Lambda
resource "aws_lambda_function" "packager" {
  filename         = data.archive_file.packager.output_path
  function_name    = "VMX3-Packager-${var.connect_instance_alias}"
  role             = var.packager_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 900
  source_code_hash = data.archive_file.packager.output_base64sha256

  environment {
    variables = {
      aws_region            = var.aws_region
      s3_recordings_bucket  = var.recordings_bucket_name
      s3_transcripts_bucket = var.transcripts_bucket_name
      package_version       = var.package_version
      presigner_function_arn = aws_lambda_function.presigner.arn
      sns_topic_arn         = var.sns_topic_arn
      url_expire_days       = var.url_expire_days
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}

# Timestamper Lambda
resource "aws_lambda_function" "timestamper" {
  filename         = data.archive_file.timestamper.output_path
  function_name    = "VMX3-Timestamper-${var.connect_instance_alias}"
  role             = var.timestamper_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  source_code_hash = data.archive_file.timestamper.output_base64sha256

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}

# Presigner Lambda
resource "aws_lambda_function" "presigner" {
  filename         = data.archive_file.presigner.output_path
  function_name    = "VMX3-Presigner-${var.connect_instance_alias}"
  role             = var.presigner_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 60
  source_code_hash = data.archive_file.presigner.output_base64sha256

  environment {
    variables = {
      aws_region      = var.aws_region
      package_version = var.package_version
      url_expire_days = var.url_expire_days
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}

# Transcribe Error Handler Lambda
resource "aws_lambda_function" "transcribe_error_handler" {
  filename         = data.archive_file.transcribe_error_handler.output_path
  function_name    = "VMX3-TranscribeErrorHandler-${var.connect_instance_alias}"
  role             = var.transcribe_error_handler_role_arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  source_code_hash = data.archive_file.transcribe_error_handler.output_base64sha256

  environment {
    variables = {
      aws_region           = var.aws_region
      s3_transcripts_bucket = var.transcripts_bucket_name
      package_version      = var.package_version
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = var.lambda_logging_level
    system_log_level      = "INFO"
  }
}
