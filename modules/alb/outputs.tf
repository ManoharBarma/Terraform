
output "alb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "The ARN of the target group."
  value       = aws_lb_target_group.this.arn
}
