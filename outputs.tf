output "audit-trail-log-group" {
  description = "Name of the CloudWatch log group containing the audit trail stream."
  value       = aws_cloudwatch_log_group.tfc-audit-trail.name
}

output "audit-trail-log-stream" {
  description = "Name of the CloudWatch log stream of the audit trail."
  value       = aws_cloudwatch_log_stream.tfc-audit-trail.name
}

output "vpc-name" {
  description = "Name of the VPC created to host the Fargate subnets."
  value       = module.tfc-audit-trail-vpc.name
}
