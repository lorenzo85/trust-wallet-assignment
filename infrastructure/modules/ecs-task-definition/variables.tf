variable "family" {
  description = "Task definition family name"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role (used by ECS agent to pull images, push logs)"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role (assumed by the container for AWS API calls)"
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096, ...)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB (must be valid for the chosen CPU)"
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "CPU architecture: X86_64 or ARM64"
  type        = string
  default     = "ARM64"
}

variable "container_name" {
  description = "Container name inside the task"
  type        = string
}

variable "image_uri" {
  description = "Full container image URI (e.g. <ecr-repo>:<tag>)"
  type        = string
}

variable "container_port" {
  description = "TCP port the container listens on"
  type        = number
}

variable "container_command" {
  description = "Override for the container command; null uses the image default"
  type        = list(string)
  default     = null
}

variable "environment" {
  description = "Environment variables injected into the container"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region (used for awslogs driver configuration)"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
