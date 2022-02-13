resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Development"
  }
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = -1
    self = true
    from_port = 0
    to_port = 0
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.allow_inbound
    content {
      protocol = ingress.value["protocol"]
      from_port = ingress.value["from_port"]
      to_port = ingress.value["to_port"]
      cidr_blocks = [ingress.value["source"]]
    }
  }
}

resource "aws_subnet" "private" {
  for_each = {
    "Production - Private AZ1" = { az = var.az1, cidr = cidrsubnet(var.cidr, 8, 0) }
    "Production - Private AZ2" = { az = var.az2, cidr = cidrsubnet(var.cidr, 8, 1) }
  }
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false

  tags = {
    Name = each.key
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Development - Private"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}