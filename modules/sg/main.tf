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
  for_each = { for rule in var.ingress_rules : rule.description => rule }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = each.value.description

  # --- CORRECTED BLOCK ---
  # This now handles both rule types safely by providing a 'null' default.
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

resource "aws_security_group_rule" "egress" {
  for_each = { for rule in var.egress_rules : rule.description => rule }

  type              = "egress"
  security_group_id = aws_security_group.this.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  description = each.value.description

  # --- CORRECTED BLOCK ---
  # This now handles both rule types safely by providing a 'null' default.
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}