output "id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "route_table" {
  value = aws_route_table.private.id
}