include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/alb"
}

dependency "vpc" {
  config_path = "../site"

  mock_outputs = {
    vpc_id            = "vpc-00000000000000000"
    public_subnet_ids = ["subnet-00000000000000001"]
    app_sg_id         = "sg-00000000000000001"
  }
}

inputs = {
  name              = "trust-wallet-proxy-dev"
  vpc_id            = dependency.vpc.outputs.vpc_id
  public_subnet_ids = dependency.vpc.outputs.public_subnet_ids
  app_sg_id         = dependency.vpc.outputs.app_sg_id
  container_port    = 8545
  health_check_path = "/health"
}
