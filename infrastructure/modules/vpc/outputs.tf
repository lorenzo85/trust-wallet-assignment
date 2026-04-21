output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs ordered by AZ"
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs ordered by AZ"
  value       = [for az in var.azs : aws_subnet.private[az].id]
}

output "app_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.app.id
}

output "private_route_table_ids" {
  description = "Private route table IDs ordered by AZ"
  value       = [for az in var.azs : aws_route_table.private[az].id]
}

output "nat_public_ips" {
  description = "Public IPs of NAT gateways ordered by AZ"
  value       = [for az in var.azs : aws_eip.nat[az].public_ip]
}
