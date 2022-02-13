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

resource "aws_iam_role" "instance" {
  name = "networking-workshop-${var.env}-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = {
    Name = "networking-workshop-${var.env}-ssm"
  }
}

resource "aws_iam_instance_profile" "instance" {
  name = "networking-workshop-${var.env}-ssm"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "all" {
  count         = length(var.subnets)
  ami           = data.aws_ami.amzn2.image_id
  instance_type = "t3.micro"

  iam_instance_profile = aws_iam_instance_profile.instance.name
  subnet_id            = var.subnets[count.index].id

  user_data = <<-EOF
  #!/bin/bash
  systemctl start amazon-ssm-agent
  systemctl enable amazon-ssm-agent
  EOF

  tags = {
    Name = "${var.env} - ${var.subnets[count.index].name}"
  }
}