output "task_definition_arn" {
  description = "ARN of the task definition (includes revision)"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family name"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Latest task definition revision number"
  value       = aws_ecs_task_definition.this.revision
}

output "log_group_name" {
  description = "CloudWatch log group name for container stdout"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.this.arn
}
