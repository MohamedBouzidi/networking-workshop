output "private_ips" {
  value = aws_instance.all[*].private_ip
}