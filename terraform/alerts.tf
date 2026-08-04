# SNS topic: the email-alert channel for the project.
resource "aws_sns_topic" "security_alerts" {
  name = "securecloud-sentinel-security-alerts"
}

# Your confirmed email subscription.
resource "aws_sns_topic_subscription" "security_alert_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

  confirmation_timeout_in_minutes = 5
}

# Detect critical security changes recorded by CloudTrail.
resource "aws_cloudwatch_event_rule" "critical_security_changes" {
  name        = "securecloud-sentinel-critical-security-changes"
  description = "Alerts on sensitive IAM, S3, and CloudTrail changes."

  event_pattern = jsonencode({
    source = [
      "aws.iam",
      "aws.s3",
      "aws.cloudtrail"
    ]

    "detail-type" = [
      "AWS API Call via CloudTrail"
    ]

    detail = {
      eventSource = [
        "iam.amazonaws.com",
        "s3.amazonaws.com",
        "cloudtrail.amazonaws.com"
      ]

      eventName = [
        "StopLogging",
        "StartLogging",
        "DeleteTrail",
        "UpdateTrail",
        "PutEventSelectors",
        "DeleteBucket",
        "PutBucketPolicy",
        "DeleteBucketPolicy",
        "PutBucketPublicAccessBlock",
        "DeletePublicAccessBlock",
        "CreateAccessKey",
        "UpdateAccessKey",
        "DeleteAccessKey",
        "DeleteUser",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "PutUserPolicy",
        "DeleteUserPolicy"
      ]
    }
  })
}

# Allow the AWS account and both EventBridge rules to publish to SNS.
data "aws_iam_policy_document" "security_alerts_sns" {
  statement {
    sid    = "AllowAccountManagement"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
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
      aws_sns_topic.security_alerts.arn
    ]
  }

  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.security_alerts.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.critical_security_changes.arn,
        aws_cloudwatch_event_rule.failed_console_logins.arn
      ]
    }
  }
}

# Apply the SNS topic policy.
resource "aws_sns_topic_policy" "security_alerts" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.security_alerts_sns.json
}

# Connect critical-security rule to SNS.
resource "aws_cloudwatch_event_target" "security_alert_email" {
  rule      = aws_cloudwatch_event_rule.critical_security_changes.name
  target_id = "SendSecurityAlertEmail"
  arn       = aws_sns_topic.security_alerts.arn

  depends_on = [
    aws_sns_topic_policy.security_alerts
  ]
}