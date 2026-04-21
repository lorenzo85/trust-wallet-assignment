# Trust Wallet - Assignment

This repository provisions the AWS infrastructure and the application code for a simple blockchain (JSON)RPC proxy that forwards requests to `polygon.drpc.org`.

**Infrastructure** (`infrastructure/` Terraform modules orchestrated with Terragrunt):
- VPC spanning 3 availability zones, each with a public and a private subnet
- NAT Gateway per AZ providing egress for tasks in the private subnets
- ECR repository hosting the proxy container image
- ECS cluster running on Fargate
- ECS task definition and service deploying the proxy across the private subnets
- Horizontal auto-scaling driven by average CPU utilisation
- Application Load Balancer fronting the service, forwarding traffic to tasks registered by IP

**Application**:
- Go RPC proxy (`proxy/`) with a minimal, scratch-based Dockerfile built for `linux/arm64`
- Simple pre/post upstream request handlers for logging and (dummy)metrics collection

## Design considerations

- **High availability**: the auto-scaler keeps at least two tasks running (`min_capacity = 2`) spread across two AZs, so a single-AZ outage still leaves the service healthy.
- **Reproducible deploys**: prefer immutable image tags (e.g. the git SHA) over `:latest`. Push the new tag, bump `local.image_tag` in `infrastructure/environments/dev/ecs/task-definition/terragrunt.hcl`, then re-apply the task definition and service to roll the change out.
- **Public domain & TLS**: in production, the ALB would sit behind a **Route 53 alias record** pointing at a company owned domain like `rpc.mycompany.com`. The ALB would terminate TLS on a 443 listener backed by an **ACM certificate whose Subject Alternative Names cover the company domain** — clients connect over HTTPS while the ALB does TLS termination and forwards plain HTTP to the ECS tasks inside the VPC.


# Requirements

| Tool       | Version  | Notes                                           |
|------------|----------|-------------------------------------------------|
| Terraform  | 1.14.6   | Enforced via `terraform_version_constraint` in `infrastructure/environments/dev/root.hcl`. |
| Terragrunt | 0.99.4   | Enforced via `terragrunt_version_constraint` in `infrastructure/environments/dev/root.hcl`. |
| AWS CLI    | v2       | For image push (`aws ecr get-login-password`) and ops commands. |
| Docker     | any      | Must support `buildx` for multi-arch builds (`--platform linux/arm64`). |
| Go         | 1.22     | Only needed for running the proxy locally; the Dockerfile handles build-for-deploy. |

The infrastructure IaC is expecting a bucket on the target account with the following naming structure:

```text
trust-wallet-tfstate-${local.environment}-${local.aws_account_id}-${local.aws_region}-an
```
If a different name is used update the `remote_state.config.bucket` property in the `root.hcl` file.

# Deploy infrastructure

Update the state bucket name in root.hcl file.

### Using Makefile

```bash
make plan AWS_ACCOUNT_ID=[TARGET_ACCOUNT_ID]
make apply AWS_ACCOUNT_ID=[TARGET_ACCOUNT_ID]
```

### Manual step by step infrastructure deployment

Follow this order in order to avoid issues with dependencies:

```bash
# Create VPC
terragrunt run --all plan --working-dir infrastructure/environments/dev/site
terragrunt run --all apply --working-dir infrastructure/environments/dev/site

# Create IAM Roles
terragrunt run --all plan --working-dir infrastructure/environments/dev/iam/roles
terragrunt run --all apply --working-dir infrastructure/environments/dev/iam/roles

# Create IAM Policies
terragrunt run --all plan --working-dir infrastructure/environments/dev/iam/policies
terragrunt run --all apply --working-dir infrastructure/environments/dev/iam/policies

# Create ECR Repository
terragrunt run --all plan --working-dir infrastructure/environments/dev/ecr/proxy
terragrunt run --all apply --working-dir infrastructure/environments/dev/ecr/proxy

# Build and push the proxy image to ECR (see instructions below)

# Create ALB
terragrunt run --all plan --working-dir infrastructure/environments/dev/alb
terragrunt run --all apply --working-dir infrastructure/environments/dev/alb

# Create ECS Cluster
terragrunt run --all plan --working-dir infrastructure/environments/dev/ecs/cluster
terragrunt run --all apply --working-dir infrastructure/environments/dev/ecs/cluster

# Create ECS Task
terragrunt run --all plan --working-dir infrastructure/environments/dev/ecs/task-definition
terragrunt run --all apply --working-dir infrastructure/environments/dev/ecs/task-definition

# Create ECS Service
terragrunt run --all plan --working-dir infrastructure/environments/dev/ecs/service
terragrunt run --all apply --working-dir infrastructure/environments/dev/ecs/service

# Create ECS Autoscaling
terragrunt run --all plan --working-dir infrastructure/environments/dev/ecs/autoscaling
terragrunt run --all apply --working-dir infrastructure/environments/dev/ecs/autoscaling
```

### Destroy the infrastructure
```bash
make destroy AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID CONFIRM=yes
```

## Build & push the proxy image

The task definition runs on Fargate **ARM64**, so the image must be cross built for `linux/arm64`.

```bash
# 1. Setup variables
export AWS_ACCOUNT_ID=[TARGET_ACCOUNT_ID]

make docker-login AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
make image-build AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
make image-push AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID

# After pushing a new image to the same `:latest` tag, ECS will NOT automatically redeploy. 
# Force a new deployment so the service pulls the updated image.
make redeploy
```


## Test the proxy

For this exercise all traffic enters through the ALB. To test the proxy, we first need to resolve the ALB's public DNS name.


```bash
# 1. Export variables about AWS env
export ALB_DNS=$(terragrunt output --raw alb_dns_name --working-dir infrastructure/environments/dev/alb)
echo $ALB_DNS

# 2. Health endpoint: verifies ALB → target group → task plumbing
curl -i http://${ALB_DNS}/health
# Expected: HTTP/1.1 200 + {"status":"ok"}

# 3. RPC call: verifies the proxy forwards to polygon.drpc.org (egress via NAT Gateway).
curl -s -X POST http://${ALB_DNS}/ \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
# Expected: {"jsonrpc":"2.0","id":1,"result":"0x..."}

curl -s -X POST http://${ALB_DNS}/ \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
# Expected: {"id":1,"jsonrpc":"2.0","result":"0x89"}
```

**Container logs** — everything the proxy Go app writes to stdout:

```bash
make logs AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
```


# Development

## Running the proxy locally

```bash
# Defaults: listens on localhost:8585, forwards to https://polygon.drpc.org
go -C proxy run .

# Override any of the three flags if needed:
go -C proxy run . \
  --addr=0.0.0.0:8585 \
  --upstream=https://polygon.drpc.org \
  --timeout=30s
  
# To build the app as a standalone binary:
go -C proxy build -o app .
./proxy/app --addr=:8585
```

Test it in another terminal:

```bash
curl -i http://localhost:8585/health
# Expected: HTTP/1.1 200 + {"status":"ok"}

curl -s -X POST http://localhost:8585/ \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
# Expected: {"jsonrpc":"2.0","id":1,"result":"0x..."} 
```
