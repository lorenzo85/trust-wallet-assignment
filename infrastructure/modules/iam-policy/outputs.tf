output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.this.arn
}

output "policy_name" {
  description = "Name of the IAM policy"
  value       = aws_iam_policy.this.name
}
