output "zone_id" {
  description = "The ID of the created Route 53 hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "A list of name servers for the hosted zone."
  value       = aws_route53_zone.this.name_servers
}