variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "trusted_services" {
  description = "AWS service principals allowed to assume this role"
  type        = list(string)
  default     = ["ecs-tasks.amazonaws.com"]
}

variable "managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
