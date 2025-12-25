resource "aws_db_subnet_group" "this" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  # --- Instance Configuration ---
  identifier            = var.db_name
  instance_class        = var.instance_class
  engine                = var.engine
  engine_version        = var.engine_version
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage # For storage autoscaling

  # --- Credentials ---
  db_name  = var.db_name
  username = var.username
  password = var.password

  # --- Networking ---
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  # --- Backup and Maintenance ---
  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az

  # --- Deletion Protection ---
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  tags = merge(
    { "Name" = var.db_name },
    var.tags
  )
}


