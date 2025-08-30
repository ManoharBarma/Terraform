# --- Core Networking Resources ---

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# --- Subnet Creation ---

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true # Instances in public subnets get public IPs
  tags = {
    Name = "${var.vpc_name}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = {
    Name = "${var.vpc_name}-private-subnet-${each.key}"
  }
}

# --- NAT Gateway (Highly Available) ---
# Creates an Elastic IP and a NAT Gateway in each Availability Zone.

resource "aws_eip" "nat" {
  for_each   = aws_subnet.public
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  subnet_id     = each.value.id
  allocation_id = aws_eip.nat[each.key].id
  tags = {
    Name = "${var.vpc_name}-nat-gateway-${each.key}"
  }
}

# --- Routing for Public Subnets ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# --- Routing for Private Subnets (Highly Available) ---
# Creates a dedicated route table for each AZ, pointing to the NAT Gateway in that same AZ.

resource "aws_route_table" "private" {
  for_each = aws_subnet.private # Create one private route table per AZ
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-private-rt-${each.key}"
  }
}

resource "aws_route" "private_nat_access" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}