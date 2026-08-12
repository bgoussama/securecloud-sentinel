# SecureCloud Sentinel — Project Summary

## Overview
SecureCloud Sentinel is an AWS cloud-security monitoring and automated incident-response lab built with Terraform.

## Key Achievements
- Designed secure CloudTrail log collection to an encrypted, versioned, private S3 bucket.
- Implemented EventBridge detections for sensitive IAM, S3, and CloudTrail actions.
- Configured SNS email alerts for critical security events and failed AWS Console login attempts.
- Developed a Lambda-based automated response that restarts CloudTrail after a StopLogging event.
- Validated the detection and response workflows through end-to-end tests.
- Added GitHub Actions CI/CD checks with Terraform validation and Trivy IaC security scanning.

## Technologies
AWS CloudTrail, S3, EventBridge, SNS, Lambda, IAM, Terraform, GitHub Actions, Docker, Trivy.

## Security Outcome
The project provides audit-log continuity, proactive alerting, automated recovery, and Infrastructure-as-Code security validation.