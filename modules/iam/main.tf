data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Recording Processor Role
resource "aws_iam_role" "recording_processor" {
  name               = "VMX3_Recording_Processor_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "recording_processor_basic" {
  role       = aws_iam_role.recording_processor.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "recording_processor" {
  name = "VMX3_Recording_Processor_Policy"
  role = aws_iam_role.recording_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${var.recordings_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "kinesis:SubscribeToShard"
        ]
        Resource = var.connect_ctr_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        Resource = [
          var.connect_recordings_bucket_arn,
          "${var.connect_recordings_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Transcriber Role
resource "aws_iam_role" "transcriber" {
  name               = "VMX3_Transcriber_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "transcriber_basic" {
  role       = aws_iam_role.transcriber.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "transcriber" {
  name = "VMX3_Transcriber_Policy"
  role = aws_iam_role.transcriber.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]
        Resource = "${var.recordings_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["transcribe:StartTranscriptionJob"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${var.transcripts_bucket_arn}/*"
      }
    ]
  })
}

# Packager Role
resource "aws_iam_role" "packager" {
  name               = "VMX3_Packager_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "packager_basic" {
  role       = aws_iam_role.packager.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "packager" {
  name = "VMX3_Packager_Policy"
  role = aws_iam_role.packager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]
        Resource = [
          "${var.recordings_bucket_arn}/*",
          "${var.transcripts_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["transcribe:DeleteTranscriptionJob"]
        # Resource = "arn:aws:transcribe:${var.aws_region}:*:transcription-job/vmx3_*"
        Resource = "arn:aws-us-gov:transcribe:${var.aws_region}:*:transcription-job/vmx3_*"
      },
      {
        Effect = "Allow"
        Action = [
          "connect:UpdateContactAttributes",
          "connect:GetContactAttributes"
        ]
        Resource = [
          var.connect_instance_arn,
          "${var.connect_instance_arn}/contact/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        # Resource = "arn:aws:lambda:${var.aws_region}:*:function:VMX3-Presigner-${var.connect_instance_alias}"
        Resource = "arn:aws-us-gov:lambda:${var.aws_region}:*:function:VMX3-Presigner-${var.connect_instance_alias}"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Timestamper Role
resource "aws_iam_role" "timestamper" {
  name               = "VMX3_Timestamper_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "timestamper_basic" {
  role       = aws_iam_role.timestamper.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Presigner Role
resource "aws_iam_role" "presigner" {
  name               = "VMX3_Presigner_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "presigner_basic" {
  role       = aws_iam_role.presigner.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "presigner" {
  name = "VMX3_Presigner_Policy"
  role = aws_iam_role.presigner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.recordings_bucket_arn,
          "${var.recordings_bucket_arn}/*"
        ]
        }
    ]
  })
}

# Transcribe Error Handler Role
resource "aws_iam_role" "transcribe_error_handler" {
  name               = "VMX3_Transcribe_Error_Handler_Role_${var.connect_instance_alias}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "transcribe_error_handler_basic" {
  role       = aws_iam_role.transcribe_error_handler.name
  # policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  policy_arn =  "arn:aws-us-gov:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "transcribe_error_handler" {
  name = "VMX3_Transcribe_Error_Handler_Policy"
  role = aws_iam_role.transcribe_error_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.transcripts_bucket_arn}/*"
      }
    ]
  })
}


