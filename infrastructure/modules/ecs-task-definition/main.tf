# ──────────────────────────────────────────────────────────────────────────────
# ECS Task Definition (Fargate) + CloudWatch log group for container stdout.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.family}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image_uri
      essential = true
      command   = var.container_command

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        },
      ]

      environment = [
        for k, v in var.environment : { name = k, value = v }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = var.container_name
        }
      }
    },
  ])

  tags = var.tags
}
