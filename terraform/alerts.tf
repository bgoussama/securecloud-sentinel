# SNS topic: the channel used to send security alert emails.
resource "aws_sns_topic" "security_alerts" {
  name = "securecloud-sentinel-security-alerts"
}

# Email subscription. It was confirmed manually through the AWS email.
resource "aws_sns_topic_subscription" "security_alert_email" {
  topic_arn                       = aws_sns_topic.security_alerts.arn
  protocol                        = "email"
  endpoint                        = var.alert_email
  confirmation_timeout_in_minutes = 5
}

# EventBridge rule: detects sensitive AWS API calls logged by CloudTrail.
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

      # Explicit list of actions considered critical for this lab.
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

# Topic policy: allows the account owner to manage the topic.
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

    resources = [aws_sns_topic.security_alerts.arn]
  }

  # Allows only this EventBridge rule to publish security alerts.
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.critical_security_changes.arn]
    }
  }
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.security_alerts_sns.json
}

# Connects the EventBridge detection rule to the SNS email-alert topic.
resource "aws_cloudwatch_event_target" "security_alert_email" {
  rule      = aws_cloudwatch_event_rule.critical_security_changes.name
  target_id = "SendSecurityAlertEmail"
  arn       = aws_sns_topic.security_alerts.arn

  depends_on = [
    aws_sns_topic_policy.security_alerts
  ]
}