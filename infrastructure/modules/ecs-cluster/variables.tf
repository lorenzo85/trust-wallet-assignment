variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
