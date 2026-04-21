include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/ecs-cluster"
}

inputs = {
  cluster_name       = "trust-wallet-proxy-dev"
  container_insights = false
}
