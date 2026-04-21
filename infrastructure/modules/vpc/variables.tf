variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones. Index i matches public_cidrs[i] and private_cidrs[i]."
  type        = list(string)
  default     = ["eu-west-1a"]
}

variable "public_cidrs" {
  description = "Public subnet CIDRs (one per AZ, hosts NAT Gateways)"
  type        = list(string)
  default     = ["10.0.0.0/24"]
}

variable "private_cidrs" {
  description = "Private subnet CIDRs (one per AZ, hosts ECS tasks)"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "project" {
  description = "Project name (used in Name tags)"
  type        = string
}

variable "environment" {
  description = "Environment name (used in Name tags)"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
