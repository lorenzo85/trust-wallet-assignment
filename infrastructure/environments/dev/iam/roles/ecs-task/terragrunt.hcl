include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/iam-role"
}

inputs = {
  # Task execution role — used by the service to access AWS services such as s3, DynamoDB, ...
  # Currently this is empty, just useful in case AWS resources need to be used e.g. using AWS SDKs.
  role_name        = "trust-wallet-proxy-dev-ecs-task"
  trusted_services = ["ecs-tasks.amazonaws.com"]
}
