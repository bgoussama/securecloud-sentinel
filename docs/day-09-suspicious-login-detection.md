# Day 9 — Suspicious Login Detection

## Objective
Detect failed AWS Management Console login attempts and notify the security operator by email.

## Detection flow
1. A user attempts to log in to the AWS Management Console.
2. CloudTrail records the ConsoleLogin event.
3. EventBridge checks whether the login result is `Failure`.
4. When the event matches, EventBridge sends it to the SNS security-alert topic.
5. Amazon SNS delivers an email alert.

## Detection rule
- Event source: `aws.signin`
- Event type: `AWS Console Sign In via CloudTrail`
- Event name: `ConsoleLogin`
- Detection condition: `ConsoleLogin = Failure`

## Verification
The EventBridge rule `securecloud-sentinel-failed-console-logins` was successfully deployed and is enabled.

## Security value
This detection helps identify possible unauthorized-access attempts and gives the security operator a rapid notification.