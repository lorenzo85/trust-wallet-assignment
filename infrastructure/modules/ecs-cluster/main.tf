# ──────────────────────────────────────────────────────────────────────────────
# ECS Cluster (Fargate only)
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1         # The first N tasks launched by any service on this cluster must go to FARGATE capacity provider.
    weight            = 100       # We only have FARGATE, hence all tasks launched will be using this FARGATE capacity provider.
    capacity_provider = "FARGATE"
  }
}
