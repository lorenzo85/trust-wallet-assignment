variable "cluster_name" {
  description = "ECS cluster name the service runs in"
  type        = string
}

variable "service_name" {
  description = "ECS service name to scale"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks the auto-scaler will keep running"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks the auto-scaler may scale out to"
  type        = number
  default     = 4
}

variable "cpu_target" {
  description = "Average CPU utilization (%) the scaler tries to maintain"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Seconds to wait after a scale-in before another scale-in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Seconds to wait after a scale-out before another scale-out"
  type        = number
  default     = 60
}
