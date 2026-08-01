output "security_logs_bucket_name" {
  description = "Name of the SecureCloud Sentinel S3 bucket."
  value       = aws_s3_bucket.security_logs.bucket
}

output "aws_region" {
  description = "AWS region used by this project."
  value       = "eu-west-3"
}