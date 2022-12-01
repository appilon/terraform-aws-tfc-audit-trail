output "audit-trail-log-group" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.tfc-audit-trail.name
}

output "audit-trail-log-stream" {
  description = "Name of the CloudWatch log stream."
  value       = aws_cloudwatch_log_stream.tfc-audit-trail.name
}
