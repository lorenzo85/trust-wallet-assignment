variable "name" {
  description = "Name used for the ALB, target group, and security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the ALB and target group live in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets the ALB nodes attach to (one per AZ)"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID of the ECS tasks; an ingress rule from the ALB SG is added to it"
  type        = string
}

variable "container_port" {
  description = "Port the target container listens on (forwarded by the ALB)"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path used by the target group health check"
  type        = string
  default     = "/health"
}

variable "idle_timeout" {
  description = "ALB idle connection timeout in seconds"
  type        = number
  default     = 60
}

variable "deregistration_delay" {
  description = "Seconds to wait before fully deregistering a draining target"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
