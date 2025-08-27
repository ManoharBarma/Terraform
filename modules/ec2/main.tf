resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  user_data              = var.user_data

  tags = merge(
    { "Name" = var.instance_name },
    var.tags
  )
}

resource "aws_eip" "this" {
  # Create an Elastic IP only if the create_eip variable is true
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-eip"
  }
}
