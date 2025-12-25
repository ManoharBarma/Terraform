resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  tags = merge(
    { "Name" = var.sg_name },
    var.tags
  )
}

resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.ingress_rules : format("ingress-%02d-%s-%d", idx, replace(coalesce(try(rule.description, ""), ""), " ", "-"), coalesce(try(rule.from_port, 0), 0)) => rule
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = try(each.value.description, null)

  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}

resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.egress_rules : format("egress-%02d-%s-%d", idx, replace(coalesce(try(rule.description, ""), ""), " ", "-"), coalesce(try(rule.from_port, 0), 0)) => rule
  }

  type              = "egress"
  security_group_id = aws_security_group.this.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = try(each.value.description, null)

  cidr_blocks              = try(each.value.cidr_blocks, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}