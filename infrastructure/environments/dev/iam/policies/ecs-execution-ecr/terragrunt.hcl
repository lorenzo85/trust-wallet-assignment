include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/iam-policy"
}

dependency "role" {
  config_path = "../../roles/ecs-execution"

  mock_outputs = {
    role_name = "trust-wallet-proxy-dev-ecs-execution"
  }
}

inputs = {
  policy_name = "trust-wallet-proxy-dev-ecs-execution-ecr"
  role_name   = dependency.role.outputs.role_name

  # Minimum permissions for a Fargate execution role:
  #  - ECR: pull the image
  #  - CloudWatch Logs: ship container stdout to the awslogs driver target
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}
