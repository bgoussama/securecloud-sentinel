# Allows AWS CloudTrail to write audit logs to the secure S3 bucket.
data "aws_iam_policy_document" "cloudtrail_s3" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      aws_s3_bucket.security_logs.arn
    ]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.security_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# Attaches the CloudTrail write policy to the logging bucket.
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.security_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_s3.json
}

# Justification: Student lab retains default CloudTrail encryption to avoid extra cost and customer-managed KMS.
#trivy:ignore:AVD-AWS-0015
# Records AWS management activity and S3 file activity.
resource "aws_cloudtrail" "security_audit" {
  name                          = "securecloud-sentinel-audit"
  s3_bucket_name                = aws_s3_bucket.security_logs.id
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # IAM, Terraform, S3 configuration, and other AWS account actions.
  advanced_event_selector {
    name = "Log all management events"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }

  # All files in this bucket are monitored, except CloudTrail's own log files.
  advanced_event_selector {
    name = "Log S3 object events except CloudTrail logs"

    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }

    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }

    field_selector {
      field           = "resources.ARN"
      starts_with     = ["${aws_s3_bucket.security_logs.arn}/"]
      not_starts_with = ["${aws_s3_bucket.security_logs.arn}/AWSLogs/"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs
  ]
}

# Deletes old log files after 30 days to control storage cost.
resource "aws_s3_bucket_lifecycle_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}