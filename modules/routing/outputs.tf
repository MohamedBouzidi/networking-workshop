output "transit_gateway" {
  value = aws_ec2_transit_gateway.main.id
}

output "target_route_table" {
  value = aws_ec2_transit_gateway_route_table.shared.id
}

output "associated_route_table" {
  value = aws_ec2_transit_gateway_route_table.members.id
}