include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/ecs-service"
}

dependency "vpc" {
  config_path = "../../site"

  mock_outputs = {
    private_subnet_ids = ["subnet-00000000000000001"]
    app_sg_id          = "sg-00000000000000001"
  }
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_arn = "arn:aws:ecs:eu-west-1:000000000000:cluster/trust-wallet-proxy-dev"
  }
}

dependency "task_definition" {
  config_path = "../task-definition"

  mock_outputs = {
    task_definition_arn = "arn:aws:ecs:eu-west-1:000000000000:task-definition/trust-wallet-proxy-dev:1"
  }
}

dependency "alb" {
  config_path = "../../alb"

  mock_outputs = {
    target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:000000000000:targetgroup/trust-wallet-proxy-dev/00000000"
  }
}

locals {
  container_name = "proxy"
  container_port = 8545
  image_tag      = "latest"
}

inputs = {
  service_name        = "trust-wallet-proxy-dev"
  cluster_arn         = dependency.cluster.outputs.cluster_arn
  task_definition_arn = dependency.task_definition.outputs.task_definition_arn

  desired_count = 1

  subnet_ids         = dependency.vpc.outputs.private_subnet_ids
  security_group_ids = [dependency.vpc.outputs.app_sg_id]
  assign_public_ip   = false

  # ECS Exec disabled: the proxy image is `FROM scratch` so there's no shell available in the docker image.
  # This is useful to exec a shell into the container provided the container is configured to have one.
  enable_execute_command = false

  load_balancer = {
    target_group_arn = dependency.alb.outputs.target_group_arn
    container_name   = local.container_name
    container_port   = local.container_port
  }
}
