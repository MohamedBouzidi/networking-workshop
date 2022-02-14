locals {
  datacenter_cidr = "172.16.0.0/16"
  reverse_domain  = "172.16"
  nameservers = {
    "ns1" = "172.16.16.53"
  }
  hosts = {
    "bastion" = "172.16.0.100"
    "web"     = "172.16.16.100"
  }

  named_conf = templatefile(
    "${path.module}/named/named.conf.tpl",
    {
      nameservers = local.nameservers
      hosts       = local.hosts
      vpc         = var.vpc_cidr
    }
  )

  named_conf_local = templatefile(
    "${path.module}/named/named.conf.local.tpl",
    {
      forward_domain           = var.domain
      reverse_domain           = "16.172.in-addr.arpa"
      reverse_domain_zone_name = local.reverse_domain
    }
  )

  forward_zone = templatefile(
    "${path.module}/named/forward.tpl",
    {
      forward_domain = var.domain
      nameservers    = local.nameservers
      hosts          = local.hosts
    }
  )

  reverse_zone = templatefile(
    "${path.module}/named/reverse.tpl",
    {
      forward_domain = var.domain
      nameservers    = local.nameservers
      hosts          = local.hosts
    }
  )

  resolv_conf = templatefile(
    "${path.module}/named/resolv.conf.tpl",
    {
      forward_domain = var.domain
      nameservers    = local.nameservers
    }
  )
}

data "aws_ami" "amzn2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "http" "myip" {
  url = "http://checkip.amazonaws.com"
}

resource "aws_vpc" "datacenter" {
  cidr_block = local.datacenter_cidr

  tags = {
    Name = "Datacenter"
  }
}

resource "aws_security_group" "private" {
  vpc_id = aws_vpc.datacenter.id

  tags = {
    Name = "Datacenter - Private"
  }
}

resource "aws_security_group_rule" "private_self" {
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private.id
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  type                     = "ingress"
}

resource "aws_security_group_rule" "private_outbound" {
  security_group_id = aws_security_group.private.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = -1
  type              = "egress"
}

resource "aws_security_group_rule" "private_public" {
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.public.id
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  type                     = "ingress"
}

resource "aws_security_group" "public" {
  vpc_id = aws_vpc.datacenter.id

  tags = {
    Name = "Datacenter - Public"
  }
}

resource "aws_security_group_rule" "public_self" {
  security_group_id        = aws_security_group.public.id
  source_security_group_id = aws_security_group.public.id
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  type                     = "ingress"
}

resource "aws_security_group_rule" "public_private" {
  security_group_id        = aws_security_group.public.id
  source_security_group_id = aws_security_group.private.id
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  type                     = "ingress"
}

resource "aws_security_group_rule" "public_outbound" {
  security_group_id = aws_security_group.public.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = -1
  type              = "egress"
}

resource "aws_security_group_rule" "public_ssh" {
  security_group_id = aws_security_group.public.id
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "ingress"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.datacenter.id
  availability_zone       = var.az1
  cidr_block              = cidrsubnet(local.datacenter_cidr, 4, 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "Datacenter - public AZ1"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.datacenter.id
  availability_zone = var.az2
  cidr_block        = cidrsubnet(local.datacenter_cidr, 4, 1)

  tags = {
    Name = "Datacenter - private AZ2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.datacenter.id

  tags = {
    Name = "Datacenter - IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.datacenter.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Datacenter - public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "Datacenter - NAT"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "Datacenter"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.datacenter.id

  tags = {
    Name = "Datacenter - private"
  }
}

resource "aws_route" "private_outbound" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_route" "private_vpc" {
  count                  = var.tgw != null ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.vpc_cidr
  network_interface_id   = aws_instance.bastion.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_string" "tunnel1_preshared_key" {
  length  = 32
  special = false
}

resource "aws_eip" "cgw" {
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "Datacenter - CGW"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.cgw.allocation_id
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  private_ip             = local.hosts["bastion"]
  source_dest_check      = false
  key_name               = "DefaultKeyPair"
  vpc_security_group_ids = [aws_security_group.public.id]
  depends_on             = [aws_instance.dns]

  user_data = <<-EOF
    #!/bin/bash

    mkdir -p /home/ec2-user/.ssh

    cat <<'SSH' > /home/ec2-user/.ssh/id_rsa
    ${chomp(tls_private_key.bastion.private_key_pem)}
    SSH

    chmod 400 /home/ec2-user/.ssh/id_rsa

    cat <<'SSH' > /home/ec2-user/.ssh/id_rsa.pub
    ${chomp(tls_private_key.bastion.public_key_pem)}
    SSH

    chown -R ec2-user:ec2-user /home/ec2-user/.ssh

    # Install OpenSwan
    yum install -y openswan

    # Enable IPv4 forwarding
    cat <<'IPV4' >> /etc/sysctl.conf
    net.ipv4.ip_forward = 1
    net.ipv4.conf.default.rp_filter = 0
    net.ipv4.conf.default.accept_source_route = 0
    IPV4

    sysctl -p

    # Create IPsec config files
    cat <<'VPN' > /etc/ipsec.d/aws.conf
    conn Tunnel1
        authby=secret
        auto=start
        left=%defaultroute
        leftid=${aws_eip.cgw.public_ip}
        right=${var.tgw != null ? aws_vpn_connection.datacenter[0].tunnel1_address : ""}
        type=tunnel
        ikelifetime=8h
        keylife=1h
        phase2alg=aes128-sha1;modp1024
        ike=aes128-sha1;modp1024
        keyingtries=%forever
        keyexchange=ike
        leftsubnet=${local.datacenter_cidr}
        rightsubnet=${var.vpc_cidr}
        dpddelay=10
        dpdtimeout=30
        dpdaction=restart_by_peer
    VPN

    cat <<'SECRET' > /etc/ipsec.d/aws.secrets
    ${aws_eip.cgw.public_ip} ${var.tgw != null ? aws_vpn_connection.datacenter[0].tunnel1_address : ""}: PSK "${random_string.tunnel1_preshared_key.result}"
    SECRET

    systemctl enable ipsec.service
    systemctl start ipsec.service

    cat <<'RESOLV' > /etc/resolv.conf
    ${chomp(local.resolv_conf)}
    RESOLV
    EOF

  tags = {
    Name = "Datacenter - bastion"
  }
}

resource "aws_instance" "dns" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  private_ip             = local.nameservers["ns1"]
  depends_on             = [aws_nat_gateway.ngw]
  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = <<-EOF
    #!/bin/bash

    mkdir -p /home/ec2-user/.ssh

    cat <<'DATA' > /home/ec2-user/.ssh/authorized_keys
    ${chomp(tls_private_key.bastion.public_key_openssh)}
    DATA

    chown -R ec2-user:ec2-user /home/ec2-user/.ssh

    yum update -y
    yum install -y bind-9.11.4-26.P2.amzn2.5.2
    yum install -y bind-utils-9.11.4-26.P2.amzn2.5.2

    cat <<'DATA' > /etc/named.conf
    ${chomp(local.named_conf)}
    DATA

    cat <<'DATA' > /etc/named/named.conf.local
    ${chomp(local.named_conf_local)}
    DATA

    chmod 755 /etc/named
    mkdir /etc/named/zones

    cat <<'DATA' > /etc/named/zones/db.${var.domain}
    ${chomp(local.forward_zone)}
    DATA

    cat <<'DATA' > /etc/named/zones/db.${local.reverse_domain}
    ${chomp(local.reverse_zone)}
    DATA

    systemctl start named
    systemctl enable named
    EOF

  tags = {
    Name = "Datacenter - nameserver"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amzn2.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  private_ip             = local.hosts["web"]
  depends_on             = [aws_instance.dns]
  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = <<-EOF
    #!/bin/bash

    mkdir -p /home/ec2-user/.ssh

    cat <<'DATA' > /home/ec2-user/.ssh/authorized_keys
    ${chomp(tls_private_key.bastion.public_key_openssh)}
    DATA

    chown -R ec2-user:ec2-user /home/ec2-user/.ssh

    # Install NGINX
    amazon-linux-extras install -y nginx1

    # Start NGINX
    systemctl enable nginx
    systemctl start nginx

    cat <<'RESOLV' > /etc/resolv.conf
    ${chomp(local.resolv_conf)}
    RESOLV
    EOF

  tags = {
    Name = "Datacenter - web"
  }
}

resource "aws_customer_gateway" "datacenter" {
  count      = var.tgw != null ? 1 : 0
  bgp_asn    = 65000
  ip_address = aws_eip.cgw.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "Datacenter"
  }
}

resource "aws_vpn_connection" "datacenter" {
  count                 = var.tgw != null ? 1 : 0
  customer_gateway_id   = aws_customer_gateway.datacenter[0].id
  transit_gateway_id    = var.tgw.id
  static_routes_only    = true
  tunnel1_preshared_key = random_string.tunnel1_preshared_key.result
  type                  = aws_customer_gateway.datacenter[0].type

  tags = {
    Name = "Datacenter"
  }
}

resource "aws_security_group_rule" "tunnel1_500" {
  count             = var.tgw != null ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public.id
  protocol          = "udp"
  from_port         = 500
  to_port           = 500
  cidr_blocks       = ["${aws_vpn_connection.datacenter[0].tunnel1_address}/32"]
}

resource "aws_security_group_rule" "tunnel1_4500" {
  count             = var.tgw != null ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.public.id
  protocol          = "udp"
  from_port         = 4500
  to_port           = 4500
  cidr_blocks       = ["${aws_vpn_connection.datacenter[0].tunnel1_address}/32"]
}

resource "aws_ec2_transit_gateway_route" "shared_services" {
  count                          = var.tgw != null ? 1 : 0
  destination_cidr_block         = local.datacenter_cidr
  transit_gateway_attachment_id  = aws_vpn_connection.datacenter[0].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.tgw.route_table
}