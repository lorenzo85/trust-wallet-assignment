include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/iam-role"
}

inputs = {
  # Execution role — used by Fargate to pull the image from ECR and ship stdout/stderr to CloudWatch Logs and bootstrapping.
  # See attached policies from: infrastructure/environments/dev/iam/policies/ecs-execution-ecr.
  role_name        = "trust-wallet-proxy-dev-ecs-execution"
  trusted_services = ["ecs-tasks.amazonaws.com"]
}
