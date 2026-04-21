include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/ecs-task-definition"
}

dependency "execution_role" {
  config_path = "../../iam/roles/ecs-execution"

  mock_outputs = {
    role_arn = "arn:aws:iam::000000000000:role/trust-wallet-proxy-dev-ecs-execution"
  }
}

dependency "task_role" {
  config_path = "../../iam/roles/ecs-task"

  mock_outputs = {
    role_arn = "arn:aws:iam::000000000000:role/trust-wallet-proxy-dev-ecs-task"
  }
}

dependency "ecr" {
  config_path = "../../ecr/proxy"

  mock_outputs = {
    repository_url = "000000000000.dkr.ecr.eu-west-1.amazonaws.com/trust-wallet-proxy"
  }
}

locals {
  container_name = "proxy"
  container_port = 8545
  image_tag      = "latest"
}

inputs = {
  family         = "trust-wallet-proxy-dev"
  region         = "eu-west-1"
  cpu            = 256
  memory         = 512
  container_name = local.container_name

  image_uri = "${dependency.ecr.outputs.repository_url}:${local.image_tag}"

  container_port = local.container_port
  container_command = [
    "--addr=0.0.0.0:${local.container_port}",
  ]

  execution_role_arn = dependency.execution_role.outputs.role_arn
  task_role_arn      = dependency.task_role.outputs.role_arn
}
