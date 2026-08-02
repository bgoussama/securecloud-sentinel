# Day 6 — CloudTrail Audit Logging

## Objective

Deploy a centralized AWS audit trail for SecureCloud Sentinel.

## Implementation

The project deploys an AWS CloudTrail trail named `securecloud-sentinel-audit`.

It is configured to:

- Record management events from all AWS regions
- Record read and write actions on objects in the SecureCloud Sentinel S3 bucket
- Deliver logs to the private S3 logging bucket
- Validate log file integrity
- Retain logs for 30 days to control storage growth

## Test performed

A controlled file upload was performed to:

`lab-tests/cloudtrail-test.txt`

CloudTrail successfully delivered compressed audit logs to the `AWSLogs/` prefix in the S3 bucket.

## Security value

CloudTrail provides accountability and forensic evidence. It helps identify who performed sensitive AWS actions, when they occurred, and from which source.