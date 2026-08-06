# SNS topic dedicated to console-login alerts in us-east-1.
resource "aws_sns_topic" "console_login_alerts" {
  provider = aws.us_east_1
  name     = "securecloud-sentinel-console-login-alerts"
}

# You will receive a new subscription-confirmation email after deployment.
resource "aws_sns_topic_subscription" "console_login_alert_email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.console_login_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  confirmation_timeout_in_minutes = 5
}

# New rule deliberately created in us-east-1.
resource "aws_cloudwatch_event_rule" "failed_console_logins_us_east_1" {
  provider    = aws.us_east_1
  name        = "securecloud-sentinel-failed-console-logins-us-east-1"
  description = "Alerts when an AWS ConsoleLogin attempt fails in us-east-1."

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

data "aws_iam_policy_document" "console_login_alerts_sns" {
  statement {
    sid    = "AllowAccountManagement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission"
    ]

    resources = [
      aws_sns_topic.console_login_alerts.arn
    ]
  }

  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["SNS:Publish"]

    resources = [
      aws_sns_topic.console_login_alerts.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.failed_console_logins_us_east_1.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "console_login_alerts" {
  provider = aws.us_east_1
  arn      = aws_sns_topic.console_login_alerts.arn
  policy   = data.aws_iam_policy_document.console_login_alerts_sns.json
}

# Target in the same region as the new EventBridge rule and SNS topic.
resource "aws_cloudwatch_event_target" "failed_console_login_email_us_east_1" {
  provider  = aws.us_east_1
  rule      = aws_cloudwatch_event_rule.failed_console_logins_us_east_1.name
  target_id = "SendFailedConsoleLoginEmail"
  arn       = aws_sns_topic.console_login_alerts.arn

  depends_on = [
    aws_sns_topic_policy.console_login_alerts
  ]
}