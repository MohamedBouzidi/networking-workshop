output "inbound_endpoint_ips" {
  value = data.aws_route53_resolver_endpoint.cloud.ip_addresses
}