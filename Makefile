## ─────────────────────────────────────────────────────────────────────────────
## Override any variable on the command line, e.g. `make apply AWS_REGION=us-east-1`
## ─────────────────────────────────────────────────────────────────────────────
AWS_REGION     ?= eu-west-1
AWS_ACCOUNT_ID =
ENVIRONMENT    ?= dev
PROJECT        ?= trust-wallet-proxy
ECR_REPO       ?= $(PROJECT)
IMAGE_TAG      ?= latest
CLUSTER        ?= $(PROJECT)-$(ENVIRONMENT)
SERVICE        ?= $(PROJECT)-$(ENVIRONMENT)

# Export so terragrunt subprocesses can read them via get_env() in root.hcl.
# Without `export`, these are Make variables only and invisible to children.
export AWS_ACCOUNT_ID
export AWS_REGION

# ECR_URI uses lazy `=` so AWS_ACCOUNT_ID is only checked when a recipe that
# actually needs it (docker-login, image-build, image-push) expands ECR_URI.
# Other targets (plan/apply, logs, smoke-test, …) don't require it.
ECR_URI         = $(if $(strip $(AWS_ACCOUNT_ID)),$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO),$(error AWS_ACCOUNT_ID is required. Pass it explicitly, e.g. `make image-push AWS_ACCOUNT_ID=123456789012`))
ENV_DIR        := infrastructure/environments/$(ENVIRONMENT)
LOG_GROUP      := /ecs/$(CLUSTER)

.DEFAULT_GOAL := help

## ─── Help ────────────────────────────────────────────────────────────────────

.PHONY: help
help:
	@echo "Environment: $(ENVIRONMENT) (override via ENVIRONMENT=<name>)"
	@echo ""
	@echo "Infrastructure:"
	@echo "  plan                Plan all infrastructure in $(ENV_DIR)"
	@echo "  apply               Apply all infrastructure in $(ENV_DIR)"
	@echo "  destroy             Destroy all infrastructure in $(ENV_DIR) (requires CONFIRM=yes)"
	@echo ""
	@echo "Per-module plan/apply (add -plan/-apply suffix):"
	@echo "  vpc, ecr, iam-roles, iam-policies, cluster, task-def, alb, service, autoscaling"
	@echo "  e.g.  make vpc-apply   /   make service-plan"
	@echo ""
	@echo "Image:"
	@echo "  docker-login        Authenticate Docker to ECR"
	@echo "  image-build         Build the proxy image for linux/arm64"
	@echo "  image-push          Build + push the proxy image to ECR"
	@echo "  redeploy            Force a new ECS deployment (picks up new image)"
	@echo ""
	@echo "Logs:"
	@echo "  logs                Tail the container log group"

## ─── Full-stack infra ────────────────────────────────────────────────────────

.PHONY: plan
plan:
	terragrunt run --all plan --working-dir $(ENV_DIR)

.PHONY: apply
apply:
	terragrunt run --all apply --working-dir $(ENV_DIR)

.PHONY: destroy
destroy:
	@if [ "$(CONFIRM)" != "yes" ]; then \
	  echo "Refusing to destroy. Re-run with CONFIRM=yes to proceed."; \
	  exit 1; \
	fi
	terragrunt run --all destroy --working-dir $(ENV_DIR)

## ─── Image build/push + redeploy ─────────────────────────────────────────────

.PHONY: docker-login
docker-login:
	@test -n "$(AWS_ACCOUNT_ID)" || \
	  { echo "AWS_ACCOUNT_ID is required. Pass it explicitly, e.g. \`make docker-login AWS_ACCOUNT_ID=123456789012\`"; exit 1; }
	aws ecr get-login-password --region $(AWS_REGION) \
	  | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

.PHONY: image-build
image-build:
	docker buildx build \
	  --platform linux/arm64 \
	  --tag $(ECR_URI):$(IMAGE_TAG) \
	  --load \
	  proxy

.PHONY: image-push
image-push: docker-login image-build
	docker push $(ECR_URI):$(IMAGE_TAG)

.PHONY: redeploy
redeploy:
	aws ecs update-service \
	  --cluster $(CLUSTER) \
	  --service $(SERVICE) \
	  --force-new-deployment \
	  --region $(AWS_REGION)

## ─── Logs ───────────────────────────────────────────────────────

.PHONY: logs
logs:
	aws logs tail $(LOG_GROUP) --follow --region $(AWS_REGION)