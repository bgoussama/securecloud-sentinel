# Day 11 — End-to-End Security Testing

## Objective
Validate the SecureCloud Sentinel detection and automated-response workflow.

## Test 1 — CloudTrail recovery
1. CloudTrail logging was stopped manually.
2. EventBridge detected the `StopLogging` event.
3. The Lambda response function was invoked.
4. Lambda restarted the audit trail with `StartLogging`.
5. Email notifications were received.
6. CloudTrail status was verified as active after the test.

## Test 2 — Failed root login detection
1. A controlled root-console authentication failure was generated.
2. CloudTrail recorded a `ConsoleLogin` event with `Failure`.
3. The event was recorded in `us-east-1`.
4. The EventBridge rule in `us-east-1` matched the event.
5. Amazon SNS delivered the failed-login alert by email.

## Result
Both detection and response paths are operational:
- Security event detection
- Email alerting
- Automated CloudTrail recovery
- Audit-log continuity