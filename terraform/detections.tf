# Detect failed AWS Console login attempts.
resource "aws_cloudwatch_event_rule" "failed_console_logins" {
  name        = "securecloud-sentinel-failed-console-logins"
  description = "Alerts when an AWS ConsoleLogin attempt fails."

  event_pattern = jsonencode({
    source = ["aws.signin"]

    "detail-type" = [
      "AWS Console Sign In via CloudTrail"
    ]

    detail = {
      eventName = ["ConsoleLogin"]

      responseElements = {
        ConsoleLogin = ["Failure"]
      }
    }
  })
}

# Send the detected event to the existing SNS email-alert topic.
resource "aws_cloudwatch_event_target" "failed_console_login_email" {
  rule      = aws_cloudwatch_event_rule.failed_console_logins.name
  target_id = "SendFailedConsoleLoginEmail"
  arn       = aws_sns_topic.security_alerts.arn

  depends_on = [
    aws_sns_topic_policy.security_alerts
  ]
}