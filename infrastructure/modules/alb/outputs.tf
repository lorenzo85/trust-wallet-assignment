output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB public DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (for Route53 alias records)"
  value       = aws_lb.this.zone_id
}

output "alb_sg_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "Target group ARN (pass to the ECS service's load_balancer block)"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}
