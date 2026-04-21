include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  vpc_cidr      = "10.0.0.0/16"
  azs           = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_cidrs  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  private_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  project     = "trust-wallet-proxy"
  environment = "dev"
}
