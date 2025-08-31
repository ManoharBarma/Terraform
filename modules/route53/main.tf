
resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = merge(
    { "Name" = var.domain_name },
    var.tags
  )
}

resource "aws_route53_record" "this" {
  for_each = { for record in var.records : "${record.name}-${record.type}" => record }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", 300) # Default TTL of 5 minutes if not specified
  records = each.value.values
}



