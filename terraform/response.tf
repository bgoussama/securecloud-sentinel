# Package the Python Lambda code into a ZIP file automatically.
data "archive_file" "restore_cloudtrail" {
  type        = "zip"
  source_file = "${path.module}/lambda/restore_cloudtrail.py"
  output_path = "${path.module}/lambda/restore_cloudtrail.zip"
}

# Trust policy: only AWS Lambda can use this role.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# IAM role used by the incident-response Lambda function.
resource "aws_iam_role" "cloudtrail_response" {
  name               = "securecloud-sentinel-cloudtrail-response"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Allow Lambda to write execution logs for troubleshooting.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.cloudtrail_response.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege permissions for the automated response.
data "aws_iam_policy_document" "cloudtrail_response_permissions" {
  statement {
    sid    = "RestartOnlyThisCloudTrail"
    effect = "Allow"

    actions = [
      "cloudtrail:StartLogging"
    ]

    resources = [
      aws_cloudtrail.security_audit.arn
    ]
  }

  statement {
    sid    = "SendResponseNotification"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.security_alerts.arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail_response_permissions" {
  name   = "securecloud-sentinel-cloudtrail-response-policy"
  role   = aws_iam_role.cloudtrail_response.id
  policy = data.aws_iam_policy_document.cloudtrail_response_permissions.json
}

# Lambda function: automatically restores CloudTrail after StopLogging.
resource "aws_lambda_function" "restore_cloudtrail" {
  function_name = "securecloud-sentinel-restore-cloudtrail"
  description   = "Restarts the SecureCloud Sentinel CloudTrail when logging is stopped."

  filename         = data.archive_file.restore_cloudtrail.output_path
  source_code_hash = data.archive_file.restore_cloudtrail.output_base64sha256

  runtime = "python3.12"
  handler = "restore_cloudtrail.lambda_handler"
  role    = aws_iam_role.cloudtrail_response.arn

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      TRAIL_NAME      = aws_cloudtrail.security_audit.name
      ALERT_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy.cloudtrail_response_permissions
  ]
}

# Detect an attempt to stop CloudTrail.
resource "aws_cloudwatch_event_rule" "cloudtrail_stopped" {
  name        = "securecloud-sentinel-cloudtrail-stopped"
  description = "Triggers automated response when CloudTrail logging is stopped."

  event_pattern = jsonencode({
    source = ["aws.cloudtrail"]

    "detail-type" = [
      "AWS API Call via CloudTrail"
    ]

    detail = {
      eventSource = ["cloudtrail.amazonaws.com"]
      eventName   = ["StopLogging"]
    }
  })
}

# Send the StopLogging event to the Lambda response function.
resource "aws_cloudwatch_event_target" "restore_cloudtrail_lambda" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_stopped.name
  target_id = "RestoreCloudTrailLogging"
  arn       = aws_lambda_function.restore_cloudtrail.arn
}

# Permit EventBridge to invoke this Lambda function only from this rule.
resource "aws_lambda_permission" "allow_eventbridge_restore_cloudtrail" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restore_cloudtrail.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudtrail_stopped.arn
}