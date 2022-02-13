resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Shared Services"
  }
}

resource "aws_subnet" "public" {
  for_each = {
    "Shared Services - Public AZ1" = { az = var.az1, cidr = cidrsubnet(var.cidr, 8, 0) }
    "Shared Services - Public AZ2" = { az = var.az2, cidr = cidrsubnet(var.cidr, 8, 1) }
  }
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "private" {
  for_each = {
    "Shared Services - Private AZ1" = { az = var.az1, cidr = cidrsubnet(var.cidr, 8, 2) }
    "Shared Services - Private AZ2" = { az = var.az2, cidr = cidrsubnet(var.cidr, 8, 3) }
  }
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false

  tags = {
    Name = each.key
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Shared Services - IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Shared Services - Public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "Shared Services - NAT"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["Shared Services - Public AZ1"].id

  tags = {
    Name = "Shared Services"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Shared Services - Private"
  }
}

resource "aws_route" "private_outbound" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}
