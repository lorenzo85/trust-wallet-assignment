# ──────────────────────────────────────────────────────────────────────────────
# Application Load Balancer (internet-facing, HTTP)
# Also opens app SG on the container port for traffic from the ALB.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.name}-sg"
  description = "ALB ${var.name} - ingress HTTP from internet, egress to app"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress (reaches tasks via app SG)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

# Allow the ALB to reach ECS tasks on the container port.
# Added here (not in the VPC module) to avoid a circular SG dependency.
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = var.app_sg_id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  description                  = "From ALB ${var.name} on container port"
}

resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  idle_timeout = var.idle_timeout

  tags = var.tags
}



# IP is a special ALB target group: a dumb list of IP:port endpoints (plus the rules for health-checking them).
# This is how the target group IP:port endpoints are populated on ECS Fargate:
#
# 1. ECS spawns a Fargate task → task gets its own ENI with a private IP in one of the private subnets.
# 2. ECS looks at the service's load_balancer block and finds container_name = "proxy" + container_port = 8545.
# 3. ECS calls elasticloadbalancing:RegisterTargets on the target group ARN, registering <task_eni_ip>:8545.
# 4. The ALB target group starts health-checking that IP at /health. Once 2 consecutive 200s come back (your healthy_threshold = 2),
# the target is marked healthy.
# 5. The ALB listener forwards incoming requests to healthy targets in the group.
# 6. When a task stops (scale in, redeploy, crash), ECS calls DeregisterTargets. ALB drains existing connections for
# deregistration_delay = 30 seconds, then removes the IP.
resource "aws_lb_target_group" "this" {
  name        = var.name
  vpc_id      = var.vpc_id
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"

  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = var.tags
}
