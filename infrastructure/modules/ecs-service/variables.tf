variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "cluster_arn" {
  description = "ARN (or name) of the ECS cluster to run the service in"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition (with revision) to run"
  type        = string
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnet IDs the tasks attach to (private subnets for most setups)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to the task ENIs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign a public IP to task ENIs (true only when running in public subnets without a NAT)"
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Allow ECS Exec (aws ecs execute-command) into running tasks"
  type        = bool
  default     = false
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower bound of healthy tasks during deployments"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Upper bound of running tasks during deployments"
  type        = number
  default     = 200
}

variable "load_balancer" {
  description = "Optional load balancer wiring. Null means no ALB/NLB attachment."
  type = object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  })
  default = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
