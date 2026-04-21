# ──────────────────────────────────────────────────────────────────────────────
# Target-tracking auto-scaling for an ECS Fargate service.
# Scales the service's desired_count to keep a metric (CPU by default) near a
# target value. Relies on Application Auto Scaling, not CloudWatch alarms.
#
# The matching ECS service should have `lifecycle.ignore_changes = [desired_count]`
# so Terraform doesn't fight the auto-scaler's adjustments.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"

  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.cpu_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}
