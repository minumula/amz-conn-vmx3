# VMX3-TF Quick Reference

## ❓ Your Questions Answered

### Q: Do we need to define inputs like Connect instance?
**A: YES** - In `terraform.tfvars`

Required inputs:
```hcl
aws_region                     = "us-east-1"
connect_instance_alias         = "myinstance"
connect_instance_arn           = "arn:aws:connect:..."           # REQUIRED
connect_recordings_bucket_arn  = "arn:aws:s3:::connect-xxx..."   # REQUIRED (existing)
connect_ctr_stream_arn         = "arn:aws:kinesis:..."           # REQUIRED (existing)
```

### Q: Do we need Connect recordings bucket info?
**A: YES** - The ARN of your EXISTING Connect recordings bucket

**Why?** Recording Processor reads IVR recordings from Connect's bucket, then writes trimmed voicemails to the NEW vmx3-recordings bucket.

**Flow:**
```
Connect Recordings Bucket (EXISTING)
         ↓ (read)
Recording Processor Lambda
         ↓ (write)
VMX3 Recordings Bucket (NEW - created by Terraform)
```

### Q: Is the code creating VM bucket and transcript buckets?
**A: YES** - Terraform creates 2 NEW buckets:

1. `vmx3-recordings-<instance>` - For processed voicemails
2. `vmx3-transcripts-<instance>` - For transcriptions

**Does NOT create:**
- Connect recordings bucket (must already exist)

### Q: How about Kinesis triggers?
**A: YES** - Automatically created

In `modules/triggers/main.tf`:
```hcl
resource "aws_lambda_event_source_mapping" "ctr_stream" {
  event_source_arn = var.connect_ctr_stream_arn  # Your existing stream
  function_name    = "VMX3-RecordingProcessor-..."
  batch_size       = 1
  filter_criteria  = { vmx3_flag = "1", ... }
}
```

**Connects your existing Kinesis stream to Recording Processor Lambda**

### Q: Any manual steps before deploying?
**A: YES** - 3 manual steps:

#### 1. Build Lambda Layer (REQUIRED)
```bash
cd layer/python
pip install pydub -t lib/python3.13/site-packages/
```

#### 2. Gather ARNs (REQUIRED)
```bash
# Connect instance ARN
aws connect list-instances

# Connect recordings bucket ARN
# From Connect Console → Data Storage → Call recordings
# Format: arn:aws:s3:::bucket-name

# Kinesis CTR stream ARN
aws kinesis list-streams
aws kinesis describe-stream --stream-name <name>
```

#### 3. Configure terraform.tfvars (REQUIRED)
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your ARNs
```

**After deployment:**
- Subscribe to SNS topic (email)
- Configure Connect flow

### Q: Is documentation updated?
**A: YES** - All docs updated:

| File | Status | Purpose |
|------|--------|---------|
| README.md | ✅ Updated | Overview with prerequisites |
| PRE_DEPLOYMENT.md | ✅ New | Detailed pre-deployment steps |
| QUICKSTART.md | ✅ Exists | 5-minute guide |
| DEPLOYMENT_CHECKLIST.md | ✅ Exists | Step-by-step checklist |
| COMPLETE_SUMMARY.md | ✅ New | Full technical details |
| WHAT_CHANGED.md | ✅ New | What changed from initial version |
| docs/CF_VS_TF.md | ✅ Updated | Accurate comparison |
| docs/DEPLOYMENT.md | ✅ Exists | Full deployment guide |
| layer/README.md | ✅ New | Layer build instructions |

---

## 📋 Pre-Deployment Checklist

- [ ] Lambda layer built (`pip install pydub -t lib/python3.13/site-packages/`)
- [ ] Connect instance ARN obtained
- [ ] Connect recordings bucket ARN obtained (EXISTING bucket)
- [ ] Kinesis CTR stream ARN obtained (EXISTING stream)
- [ ] terraform.tfvars configured with all ARNs
- [ ] AWS credentials configured
- [ ] Terraform >= 1.5 installed

---

## 🚀 Deployment Command

```bash
terraform init
terraform plan   # Review: should create ~30 resources
terraform apply  # Type 'yes'
```

---

## 📦 What Gets Created

### NEW Resources (created by Terraform)
- ✅ 2 S3 buckets (vmx3-recordings, vmx3-transcripts)
- ✅ 6 Lambda functions
- ✅ 1 SNS topic
- ✅ 6 IAM roles
- ✅ 1 IAM user (for presigner)
- ✅ 1 Secrets Manager secret
- ✅ 3 EventBridge rules
- ✅ 1 Kinesis event mapping
- ✅ 1 Connect Lambda association

### EXISTING Resources (must already exist)
- ⚠️ Connect instance
- ⚠️ Connect recordings bucket
- ⚠️ Kinesis CTR stream

---

## 🔗 Resource Relationships

```
EXISTING: Connect Instance
    ↓ (stores recordings in)
EXISTING: Connect Recordings Bucket
    ↓ (read by)
NEW: Recording Processor Lambda
    ↓ (writes to)
NEW: VMX3 Recordings Bucket
    ↓ (triggers)
NEW: Transcriber Lambda
    ↓ (writes to)
NEW: VMX3 Transcripts Bucket
    ↓ (triggers)
NEW: Packager Lambda
    ↓ (invokes)
NEW: Presigner Lambda
    ↓ (publishes to)
NEW: SNS Topic
    ↓ (sends to)
Email Subscribers
```

---

## ⚠️ Common Mistakes

### ❌ Forgot to build Lambda layer
**Error:** "No such file or directory: layer/python/lib"
**Fix:** `cd layer/python && pip install pydub -t lib/python3.13/site-packages/`

### ❌ Wrong Connect recordings bucket ARN
**Error:** Recording Processor can't read files
**Fix:** Use ARN of bucket where Connect stores IVR recordings

### ❌ Kinesis stream not configured for CTR
**Error:** No events trigger Recording Processor
**Fix:** Verify Kinesis stream is configured in Connect for CTR streaming

### ❌ Didn't subscribe to SNS
**Error:** No emails received
**Fix:** `aws sns subscribe --topic-arn <ARN> --protocol email --notification-endpoint your@email.com`

---

## 📞 Quick Help

- **Pre-deployment:** See [PRE_DEPLOYMENT.md](PRE_DEPLOYMENT.md)
- **Step-by-step:** See [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **5-minute guide:** See [QUICKSTART.md](QUICKSTART.md)
- **Full details:** See [COMPLETE_SUMMARY.md](COMPLETE_SUMMARY.md)
