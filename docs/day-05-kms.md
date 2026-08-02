# Day 5 — Encryption and AWS KMS Design

## Current implementation

The SecureCloud Sentinel S3 logging bucket uses server-side encryption with Amazon S3 managed keys (SSE-S3 / AES256).

This provides encryption at rest with no additional key-management cost.

## Why AWS KMS was evaluated

AWS Key Management Service (KMS) provides stronger operational control over encryption keys:

- Fine-grained key permissions through IAM and KMS key policies
- Auditability of key usage through AWS CloudTrail
- Key rotation and key lifecycle management
- Ability to disable a key during a security incident

## Design decision

A customer-managed KMS key was not deployed in the lab environment because it has a monthly cost.

For this low-cost learning environment, SSE-S3 is the appropriate baseline. In a production environment handling sensitive logs, the bucket could be upgraded to SSE-KMS with a customer-managed key and an enabled S3 Bucket Key.

## Comparison

| Feature | SSE-S3 (current) | SSE-KMS |
|---|---|---|
| Encryption at rest | Yes | Yes |
| Key management | AWS/S3 manages it | Controlled through AWS KMS |
| Fine-grained key permissions | No | Yes |
| Key-usage audit | Limited | Yes, through CloudTrail |
| Additional KMS costs | No | Possible |
| Chosen for this lab | Yes | Architecture documented only |