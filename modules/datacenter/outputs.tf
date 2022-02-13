output "nameserver_ip" {
  value = aws_instance.dns.private_ip
}