# Day 10 — Automated Incident Response

## Objective
Automatically restore AWS audit logging if CloudTrail is stopped.

## Response workflow
1. CloudTrail records a `StopLogging` API event.
2. EventBridge detects this event.
3. EventBridge invokes the `securecloud-sentinel-restore-cloudtrail` Lambda function.
4. Lambda calls `cloudtrail:StartLogging` for the SecureCloud Sentinel audit trail.
5. Lambda sends an email notification through Amazon SNS.

## Security controls
- The Lambda role follows least privilege.
- It can start only the `securecloud-sentinel-audit` trail.
- It can publish only to the project SNS security-alert topic.
- Only the dedicated EventBridge rule can invoke the Lambda function.

## Verification
The Lambda function was deployed successfully with Python 3.12 and is ready to receive EventBridge events.

## Security value
This automated containment action reduces the time during which audit logging could be disabled.