# Day 8 — Security Review

## Objective
Verify that the SecureCloud Sentinel infrastructure remains secure and matches its Terraform configuration.

## Verification results
- Terraform plan: no configuration drift detected.
- S3 default encryption: enabled with SSE-S3 (AES256).
- S3 public access: fully blocked.
- S3 versioning: enabled.
- CloudTrail: active and delivering audit logs successfully.
- EventBridge critical-security rule: enabled.
- SNS email subscription: confirmed and operational.

## Finding
The Terraform IAM user currently has AdministratorAccess. This is acceptable temporarily for a learning lab, but it violates the least-privilege principle. It will be reduced during the final hardening and cleanup phase.

## Conclusion
The logging, detection, and email-alerting pipeline is operational and the storage bucket is protected against public exposure.