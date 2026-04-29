locals {
  instance_id = split("/", var.connect_instance_arn)[1]
}

module "storage" {
  source = "./modules/storage"

  connect_instance_id         = local.instance_id
  connect_instance_alias      = var.connect_instance_alias
  recordings_expire_days      = var.recordings_expire_days
  expired_recording_behavior  = var.expired_recording_behavior
  enable_bucket_versioning    = var.enable_bucket_versioning
}

module "iam" {
  source = "./modules/iam"

  connect_instance_alias      = var.connect_instance_alias
  connect_instance_arn        = var.connect_instance_arn
  connect_recordings_bucket_arn = var.connect_recordings_bucket_arn
  connect_ctr_stream_arn      = var.connect_ctr_stream_arn
  recordings_bucket_arn       = module.storage.recordings_bucket_arn
  transcripts_bucket_arn      = module.storage.transcripts_bucket_arn
  aws_region                  = var.aws_region
  sns_topic_arn               = module.storage.sns_topic_arn
}

module "lambda" {
  source = "./modules/lambda"

  connect_instance_alias    = var.connect_instance_alias
  aws_region                = var.aws_region
  package_version           = var.package_version
  lambda_logging_level      = var.lambda_logging_level
  recordings_bucket_name    = module.storage.recordings_bucket_name
  transcripts_bucket_name   = module.storage.transcripts_bucket_name
  
  recording_processor_role_arn = module.iam.recording_processor_role_arn
  transcriber_role_arn         = module.iam.transcriber_role_arn
  packager_role_arn            = module.iam.packager_role_arn
  timestamper_role_arn         = module.iam.timestamper_role_arn
  presigner_role_arn           = module.iam.presigner_role_arn
  transcribe_error_handler_role_arn = module.iam.transcribe_error_handler_role_arn
  
  sns_topic_arn    = module.storage.sns_topic_arn
  url_expire_days  = var.url_expire_days
  
}

module "triggers" {
  source = "./modules/triggers"

  connect_instance_alias    = var.connect_instance_alias
  connect_instance_arn      = var.connect_instance_arn
  connect_instance_id       = local.instance_id
  connect_ctr_stream_arn    = var.connect_ctr_stream_arn
  recordings_bucket_name    = module.storage.recordings_bucket_name
  recordings_bucket_arn     = module.storage.recordings_bucket_arn
  transcripts_bucket_name   = module.storage.transcripts_bucket_name
  transcripts_bucket_arn    = module.storage.transcripts_bucket_arn
  
  recording_processor_function_name = module.lambda.recording_processor_function_name
  recording_processor_function_arn  = module.lambda.recording_processor_function_arn
  transcriber_function_arn          = module.lambda.transcriber_function_arn
  packager_function_arn             = module.lambda.packager_function_arn
  timestamper_function_arn          = module.lambda.timestamper_function_arn
  transcribe_error_handler_function_arn = module.lambda.transcribe_error_handler_function_arn
}
