# Pre-Deployment Requirements

## 1. Build Lambda Layer (REQUIRED)
```bash
cd layer/python
pip install pydub -t lib/python3.13/site-packages/
```

## 2. Gather ARNs (REQUIRED)
- Connect instance ARN
- Connect recordings bucket ARN (existing)
- Kinesis CTR stream ARN (existing)

## 3. Configure terraform.tfvars (REQUIRED)
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your ARNs
```

## 4. Deploy
```bash
terraform init
terraform plan
terraform apply
```

## 5. Subscribe to SNS (Post-deployment)
```bash
aws sns subscribe --topic-arn <from outputs> --protocol email --notification-endpoint your@email.com
```

## 6. Configure Connect Flow
- Set vmx3_flag = "1"
- Invoke Timestamper Lambda
- Set vmx3_lang, vmx3_queue_arn
- Enable IVR recording
