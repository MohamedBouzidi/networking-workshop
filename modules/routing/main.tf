resource "aws_ec2_transit_gateway" "main" {
  tags = {
    Name = "networking-workshop"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "all" {
  count              = length(var.attachments)
  subnet_ids         = var.attachments[count.index].subnets
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.attachments[count.index].id

  tags = {
    Name = var.attachments[count.index].name
  }
}

resource "aws_ec2_transit_gateway_route" "shared_services" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.all[index(var.attachments.*.shared_services, true)].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.main.propagation_default_route_table_id
}

resource "aws_route" "all" {
  count                  = length(var.attachments)
  route_table_id         = var.attachments[count.index].route_table
  destination_cidr_block = var.attachments[count.index].destination
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

resource "aws_route" "extra" {
  count                  = length(var.routes)
  route_table_id         = var.routes[count.index].route_table
  destination_cidr_block = var.routes[count.index].destination
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}