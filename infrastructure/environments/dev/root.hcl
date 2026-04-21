locals {
  project     = "trust-wallet-proxy"
  environment = "dev"
  aws_region  = "eu-west-1"

  # AWS_ACCOUNT_ID must be set in the environment (or passed via `make … AWS_ACCOUNT_ID=…`).
  # Terragrunt fails loudly at init time if unset, which is the behaviour we want —
  # an unset account ID would silently point the state bucket at the wrong owner.
  aws_account_id = get_env("AWS_ACCOUNT_ID")
}

# Pin required tool versions. terragrunt/terraform refuse to run if the local
# binary doesn't satisfy these constraints, which keeps state files safe from
# older toolchains that may produce incompatible plans.
terragrunt_version_constraint = ">= 0.99.4"
terraform_version_constraint  = ">= 1.14.6"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "trust-wallet-tfstate-${local.environment}-${local.aws_account_id}-${local.aws_region}-an"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = local.aws_region
    encrypt = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "${local.project}"
      Environment = "${local.environment}"
      ManagedBy   = "terraform"
    }
  }
}
EOF
}
