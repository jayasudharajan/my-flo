locals {
  ami_filters = {
    name                = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
    virtualization-type = ["hvm"]
  }

  ami                   = data.aws_ami.ubuntu.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  dynamic "filter" {
    for_each = local.ami_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "ntp-server-sg" {
  name = "ntp-server-sg"
  description = "Allow inbound ntp traffic"
  vpc_id = aws_vpc.lte-vpc.id
  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 123
    protocol = "tcp"
    to_port = 123
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 123
    protocol = "udp"
    to_port = 123
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 323
    protocol = "tcp"
    to_port = 323
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 323
    protocol = "udp"
    to_port = 323
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ntp-server-sg"
  }
}

resource "aws_instance" "lte-ntp" {
  for_each  = data.aws_subnet_ids.private_subnets.ids
  subnet_id = each.value

  ami = data.aws_ami.ubuntu.id
  instance_type = "m6g.medium"
  vpc_security_group_ids = [aws_security_group.ntp-server-sg.id]
  key_name = var.lte_vpc_key_pair
  associate_public_ip_address = false
  tags = {
    Name = "lte-ntp"
  }
  root_block_device {
    delete_on_termination = true
    encrypted = true
  }
}

resource "aws_route53_record" "lte-ntp" {
  allow_overwrite = false
  name            = "ntp.lte.flotech.co"
  ttl             = 60
  type            = "A"
  zone_id         = aws_route53_zone.lte.zone_id

  records = [
    aws_instance.lte-ntp[aws_subnet.private-a.id].private_ip,
    aws_instance.lte-ntp[aws_subnet.private-b.id].private_ip,
    aws_instance.lte-ntp[aws_subnet.private-c.id].private_ip
  ]
}
