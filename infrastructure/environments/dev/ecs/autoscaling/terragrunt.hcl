include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/ecs-service-autoscaling"
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_name = "trust-wallet-proxy-dev"
  }
}

dependency "service" {
  config_path = "../service"

  mock_outputs = {
    service_name = "trust-wallet-proxy-dev"
  }
}

inputs = {
  cluster_name = dependency.cluster.outputs.cluster_name
  service_name = dependency.service.outputs.service_name

  min_capacity = 2 # Spread across 2 AZs
  max_capacity = 3 # Max 1 on each AZs

  cpu_target         = 60
  scale_in_cooldown  = 300
  scale_out_cooldown = 60
}
