variable "policy_name" {
  description = "Name of the IAM policy"
  type        = string
}

variable "policy_json" {
  description = "JSON-encoded IAM policy document"
  type        = string
}

variable "role_name" {
  description = "IAM role name to attach this policy to"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
