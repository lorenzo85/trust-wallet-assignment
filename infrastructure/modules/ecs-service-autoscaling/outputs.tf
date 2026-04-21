output "scalable_target_resource_id" {
  description = "Application Auto Scaling resource ID (service/<cluster>/<service>)"
  value       = aws_appautoscaling_target.this.resource_id
}

output "cpu_policy_arn" {
  description = "ARN of the CPU target-tracking scaling policy"
  value       = aws_appautoscaling_policy.cpu.arn
}
