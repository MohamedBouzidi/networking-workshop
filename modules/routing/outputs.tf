output "tgw" {
  value = {
    id          = aws_ec2_transit_gateway.main.id
    route_table = aws_ec2_transit_gateway.main.propagation_default_route_table_id
  }
}