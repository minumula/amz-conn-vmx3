resource "aws_s3_bucket" "recordings" {
  bucket = "vmx3-recordings-${var.connect_instance_alias}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "recordings" {
  count  = var.enable_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.recordings.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "recordings" {
  bucket      = aws_s3_bucket.recordings.id
  eventbridge = true
}

resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  count  = var.expired_recording_behavior != "keep" ? 1 : 0
  bucket = aws_s3_bucket.recordings.id

  rule {
    id     = "vmx3-lifecycle"
    status = "Enabled"

    dynamic "expiration" {
      for_each = var.expired_recording_behavior == "delete" ? [1] : []
      content {
        days = var.recordings_expire_days
      }
    }

    dynamic "transition" {
      for_each = var.expired_recording_behavior == "glacier" ? [1] : []
      content {
        days          = var.recordings_expire_days
        storage_class = "GLACIER"
      }
    }
  }
}

resource "aws_s3_bucket" "transcripts" {
  bucket = "vmx3-transcripts-${var.connect_instance_alias}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "transcripts" {
  bucket = aws_s3_bucket.transcripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "transcripts" {
  count  = var.enable_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.transcripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "transcripts" {
  bucket = aws_s3_bucket.transcripts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "transcripts" {
  bucket = aws_s3_bucket.transcripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "transcripts" {
  bucket      = aws_s3_bucket.transcripts.id
  eventbridge = true
}

# SNS Topic for Voicemail Notifications
resource "aws_sns_topic" "voicemail" {
  name = "vmx3-voicemail-notifications-${var.connect_instance_alias}"
}

# SNS Topic Subscription Praveen Minula
resource "aws_sns_topic_subscription" "email_target1" {
 topic_arn = aws_sns_topic.voicemail.arn
 protocol  = "email"
 endpoint  = "pminumula@tva.gov" # replace with actual email address
}


# SNS Topic Subscription Michael Cruz
resource "aws_sns_topic_subscription" "email_target2" {
 topic_arn = aws_sns_topic.voicemail.arn
 protocol  = "email"
 endpoint  = "mscruz@tva.gov" # replace with actual email address
}