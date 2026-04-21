# ──────────────────────────────────────────────────────────────────────────────
# ECS Service (Fargate)
# Optional load_balancer block — set `load_balancer` to attach a target group.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = var.task_definition_arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  propagate_tags  = "SERVICE"

  enable_execute_command = var.enable_execute_command

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer == null ? [] : [var.load_balancer]
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  # The service's desired_count is managed by this module, but task_definition
  # changes are expected (image pushes bump the revision).
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}
