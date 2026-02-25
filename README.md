# VMX3 Terraform

Terraform implementation of Voicemail Express for Amazon Connect with SNS email delivery.

## Architecture

```
Contact Flow (vmx3_flag=1)
    ↓
Timestamper Lambda (sets timestamp)
    ↓
Kinesis CTR Stream
    ↓
Recording Processor Lambda → S3 Recordings
    ↓
Transcriber Lambda → Amazon Transcribe → S3 Transcripts
    ↓
Packager Lambda
    ↓
Presigner Lambda (generates presigned URL)
    ↓
SNS Topic → Email with transcript + presigned URL
```

## What's Included

- ✅ 6 Lambda Functions (Recording Processor, Transcriber, Packager, Presigner, Timestamper, Error Handler)
- ✅ S3 buckets (recordings, transcripts)
- ✅ IAM roles and policies
- ✅ SNS topic for email notifications
- ✅ Secrets Manager for presigner credentials
- ✅ EventBridge rules
- ✅ Kinesis event source mapping
- ✅ Connect Lambda integration (Timestamper)

## What's Excluded

- ❌ Amazon Connect Tasks (standard and guided)
- ❌ SES templates
- ❌ Contact flows
- ❌ GenAI summaries

## Quick Start

### Prerequisites (REQUIRED)

**See [PRE_DEPLOYMENT.md](PRE_DEPLOYMENT.md) for full details**

1. **Build Lambda Layer:**
   ```bash
   cd layer/python
   pip install pydub -t lib/python3.13/site-packages/
   cd ../..
   ```

2. **Gather Required ARNs:**
   - Connect instance ARN (from AWS Console)
   - Connect recordings bucket ARN (existing S3 bucket where Connect stores recordings)
   - Kinesis CTR stream ARN (existing stream for contact records)

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your ARNs
```

Required values:
```hcl
connect_instance_arn           = "arn:aws:connect:..."
connect_recordings_bucket_arn  = "arn:aws:s3:::connect-xxx-recordings"  # EXISTING bucket
connect_ctr_stream_arn         = "arn:aws:kinesis:..."
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

**Creates:**
- 2 NEW S3 buckets (vmx3-recordings, vmx3-transcripts)
- 6 Lambda functions
- SNS topic
- IAM roles
- Kinesis event mapping
- EventBridge rules

### 3. Subscribe to SNS Topic

```bash
# Get SNS topic ARN from outputs
aws sns subscribe \
  --topic-arn <SNS_TOPIC_ARN> \
  --protocol email \
  --notification-endpoint your-email@example.com

# Confirm subscription in email
```

### 4. Configure Connect Flow

Add these contact attributes in your flow:
```
Set contact attributes:
  vmx3_flag = "1"
  vmx3_lang = "en-US"
  vmx3_queue_arn = $.Queue.ARN

Invoke AWS Lambda function:
  Function: VMX3-Timestamper-<instance>
  Store result as: vmx3_timestamp
```

Enable IVR recording before setting vmx3_flag.

## Lambda Functions

1. **Timestamper** - Invoked from Connect flow to set recording timestamp
2. **Recording Processor** - Extracts voicemail from IVR recording
3. **Transcriber** - Submits audio to Amazon Transcribe
4. **Packager** - Orchestrates presigner and sends SNS notification
5. **Presigner** - Generates presigned URL for recording access
6. **Error Handler** - Handles transcription failures

## Outputs

- `recordings_bucket_name` - S3 bucket for voicemail recordings
- `transcripts_bucket_name` - S3 bucket for transcripts
- `sns_topic_arn` - SNS topic for email notifications
- `timestamper_function_arn` - Use this in Connect flow

## Email Format

Emails sent via SNS include:
- Contact ID
- Queue ARN
- Full transcript
- Presigned URL to recording (expires in 7 days by default)

## Cost Estimate

Monthly costs (approximate, 1000 voicemails/month, 1 min avg):
- S3 storage: ~$0.50
- Lambda: ~$3.00
- Transcribe: ~$24.00
- SNS: ~$0.50
- Secrets Manager: ~$0.40
- **Total: ~$28.50/month**

## Cleanup

```bash
# Empty S3 buckets first
aws s3 rm s3://vmx3-recordings-INSTANCE --recursive
aws s3 rm s3://vmx3-transcripts-INSTANCE --recursive

# Destroy infrastructure
terraform destroy
```

## Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Quick Start](QUICKSTART.md)
- [Layer Build Instructions](layer/README.md)

## License

Apache 2.0 - See LICENSE file
