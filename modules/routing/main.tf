resource "aws_ec2_transit_gateway" "main" {

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "networking-workshop"
  }
}

resource "aws_ec2_transit_gateway_route_table" "shared" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "networking-workshop - Shared"
  }
}

resource "aws_ec2_transit_gateway_route_table" "members" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "networking-workshop - Members"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  count              = length(var.shared)
  vpc_id             = var.shared[count.index].id
  subnet_ids         = var.shared[count.index].subnets
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = var.shared[count.index].name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "members" {
  count              = length(var.members)
  vpc_id             = var.members[count.index].id
  subnet_ids         = var.members[count.index].subnets
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = var.members[count.index].name
  }
}

resource "aws_ec2_transit_gateway_route" "shared_services" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.members.id
}

resource "aws_ec2_transit_gateway_route" "members" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.members)
  destination_cidr_block         = var.members[count.index].cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.members[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.shared)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared.id
}

resource "aws_ec2_transit_gateway_route_table_association" "members" {
  count                          = length(aws_ec2_transit_gateway_vpc_attachment.members)
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.members[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.members.id
}

resource "aws_route" "shared" {
  count                  = length(var.shared)
  route_table_id         = var.shared[count.index].route_table
  destination_cidr_block = var.shared[count.index].destination
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

resource "aws_route" "members" {
  count                  = length(var.members)
  route_table_id         = var.members[count.index].route_table
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

resource "aws_route" "extra" {
  count                  = length(var.routes)
  route_table_id         = var.routes[count.index].route_table
  destination_cidr_block = var.routes[count.index].destination
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}