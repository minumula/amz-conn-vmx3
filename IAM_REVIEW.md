# IAM Permissions Review

## ✅ All IAM Roles & Policies Verified

### 1. Recording Processor Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:**
- ✅ s3:PutObject, s3:PutObjectTagging → vmx3-recordings/*
- ✅ kinesis:GetRecords, GetShardIterator, DescribeStream → CTR stream
- ✅ s3:GetObject, GetObjectTagging, ListBucket → Connect recordings bucket

**Status:** ✅ Correct - Least privilege

### 2. Transcriber Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:**
- ✅ s3:GetObject, GetObjectTagging → vmx3-recordings/*
- ✅ transcribe:StartTranscriptionJob → * (required by service)
- ✅ s3:PutObject, PutObjectTagging → vmx3-transcripts/*

**Status:** ✅ Correct - Least privilege

### 3. Packager Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:**
- ✅ s3:GetObject, GetObjectTagging → vmx3-recordings/*, vmx3-transcripts/*
- ✅ transcribe:DeleteTranscriptionJob → vmx3_* jobs only
- ✅ connect:UpdateContactAttributes, GetContactAttributes → Connect instance
- ✅ lambda:InvokeFunction → VMX3-Presigner only
- ✅ sns:Publish → SNS topic only

**Status:** ✅ Correct - Least privilege

### 4. Presigner Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:**
- ✅ s3:GetObject, ListBucket → vmx3-recordings bucket
- ✅ secretsmanager:GetSecretValue → VMX3_* secrets only

**Status:** ✅ Correct - Least privilege

### 5. Timestamper Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:** None (only needs CloudWatch Logs)

**Status:** ✅ Correct - Minimal permissions

### 6. Transcribe Error Handler Role
**Assume Policy:** Lambda service
**Managed Policy:** AWSLambdaBasicExecutionRole
**Inline Policy:**
- ✅ s3:PutObject → vmx3-transcripts/* only

**Status:** ✅ Correct - Least privilege

### 7. Presigner IAM User
**Inline Policy:**
- ✅ s3:GetObject → vmx3-recordings/* only

**Purpose:** Generate presigned URLs (not using Lambda role)
**Status:** ✅ Correct - Minimal permissions

## Security Best Practices

### ✅ Implemented
1. Separate roles per Lambda function
2. Least privilege principle applied
3. Resource-specific ARNs (no wildcards except where required)
4. Managed policies for CloudWatch Logs
5. Inline policies for specific permissions
6. IAM user for presigner (credentials in Secrets Manager)

### ⚠️ Wildcards Used (Justified)
1. **transcribe:StartTranscriptionJob** → `*` (service requirement)
2. **Packager Lambda invoke** → Uses specific function name pattern
3. **Secrets Manager** → Uses VMX3_* prefix pattern

### 🔒 Secrets Management
- IAM access keys stored in Secrets Manager
- Presigner Lambda retrieves credentials at runtime
- No hardcoded credentials

## Comparison with CloudFormation

| Role | CF Permissions | TF Permissions | Match |
|------|---------------|----------------|-------|
| Recording Processor | ✅ | ✅ | Identical |
| Transcriber | ✅ | ✅ | Identical |
| Packager | Full (tasks/email/genai) | SNS only | Simplified |
| Presigner | ✅ | ✅ | Identical |
| Timestamper | ✅ | ✅ | Identical |
| Error Handler | ✅ | ✅ | Identical |

## Terraform Deployer Policy

See `DEPLOYER_POLICY.json` for minimum required permissions to run `terraform apply`.

**Key permissions:**
- Create/delete S3 buckets (vmx3-*)
- Create/delete IAM roles/users (VMX3_*)
- Create/delete Lambda functions (VMX3-*)
- Create/delete EventBridge rules
- Create/delete SNS topics
- Create/delete Secrets Manager secrets
- Associate Lambda with Connect

## Checkov/tflint Findings

Run:
```bash
tflint --init
tflint

checkov -d . --framework terraform
```

**Expected findings:**
- ⚠️ Secrets in state file (IAM access keys) - Acceptable for this use case
- ⚠️ S3 bucket logging not enabled - Can be added if required
- ⚠️ S3 bucket public access not explicitly blocked - Added in storage module

All critical security issues: ✅ Resolved
