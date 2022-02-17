resource "aws_security_group" "outbound_resolver_endpoint" {
  name   = "datacenter-outbound-resolver-endpoint"
  vpc_id = var.target_vpc.id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.target_vpc.cidr]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.target_vpc.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.allowed_vpcs[*].cidr
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.allowed_vpcs[*].cidr
  }

  tags = {
    Name = "Datacenter - Outbound Endpoint"
  }
}

resource "aws_route53_resolver_endpoint" "private" {
  name      = "datacenter-private"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.outbound_resolver_endpoint.id]

  dynamic "ip_address" {
    for_each = var.target_vpc.subnets
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "Datacenter - Private"
  }
}

resource "aws_route53_resolver_rule" "private" {
  domain_name          = var.domain
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.private.id

  target_ip {
    ip = var.nameserver
  }

  tags = {
    Name = "Datacenter - Private"
  }
}

resource "aws_route53_resolver_rule_association" "main" {
  name             = "Shared Services"
  resolver_rule_id = aws_route53_resolver_rule.private.id
  vpc_id           = var.target_vpc.id
}

resource "aws_route53_resolver_rule_association" "allowed" {
  count            = length(var.allowed_vpcs)
  name             = var.allowed_vpcs[count.index].name
  resolver_rule_id = aws_route53_resolver_rule.private.id
  vpc_id           = var.allowed_vpcs[count.index].id
}

resource "aws_route53_zone" "cloud_domain" {
  name          = var.cloud_domain
  force_destroy = true
  vpc {
    vpc_id = var.target_vpc.id
  }

  tags = {
    Name = "Cloud - private"
  }
}

resource "aws_route53_zone_association" "cloud_domain" {
  count   = length(var.allowed_vpcs)
  zone_id = aws_route53_zone.cloud_domain.id
  vpc_id  = var.allowed_vpcs[count.index].id
}

resource "aws_route53_record" "cloud_records" {
  count   = length(var.cloud_records)
  zone_id = aws_route53_zone.cloud_domain.id
  name    = "${var.cloud_records[count.index].name}.${var.cloud_domain}"
  type    = "A"
  ttl     = "300"
  records = [var.cloud_records[count.index].ip]
}

resource "aws_security_group" "inbound_resolver_endpoint" {
  name   = "datacenter-inbound-resolver-endpoint"
  vpc_id = var.target_vpc.id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["${var.nameserver}/32"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["${var.nameserver}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.allowed_vpcs[*].cidr
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.allowed_vpcs[*].cidr
  }

  tags = {
    Name = "Datacenter - Inbound Endpoint"
  }
}

resource "aws_route53_resolver_endpoint" "cloud" {
  name      = "cloud-private"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.inbound_resolver_endpoint.id]

  dynamic "ip_address" {
    for_each = var.target_vpc.subnets
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "Cloud - Private"
  }
}

data "aws_route53_resolver_endpoint" "cloud" {
  resolver_endpoint_id = aws_route53_resolver_endpoint.cloud.id
}