# Day 7 — Security Alerting

## Objective

Convert sensitive AWS security events into near-real-time email alerts.

## Architecture

CloudTrail records AWS management activity. EventBridge evaluates selected critical events and sends matching alerts to Amazon SNS. SNS delivers the notification by email.

## Critical events monitored

- CloudTrail start, stop, update, and deletion
- S3 bucket deletion and bucket-policy changes
- Public-access configuration changes
- IAM access-key creation, update, or deletion
- IAM user deletion and permission changes

## Tests performed

1. A direct Amazon SNS test email was received successfully.
2. A `StartLogging` CloudTrail event triggered the EventBridge rule.
3. A second email alert was received, validating the complete detection pipeline.

## Security value

The solution reduces response time by notifying the security operator when high-risk AWS actions occur.