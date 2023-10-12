resource "aws_security_group" "dns-server-sg" {
  name = "dns-server-sg"
  description = "Allow inbound DNS traffic"
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
    from_port = 53
    protocol = "tcp"
    to_port = 53
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 53
    protocol = "udp"
    to_port = 53
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "dns-server-sg"
  }
}

resource "aws_instance" "lte-dns-a" {
  ami = "ami-0f846ea6472ae64f0"
  instance_type = "c5a.xlarge"
  vpc_security_group_ids = [aws_security_group.dns-server-sg.id]
  availability_zone = "us-west-2a"
  key_name = var.lte_vpc_key_pair
  subnet_id = aws_subnet.public-a.id
  associate_public_ip_address = true
  tags = {
    Name = "lte-dns-1"
  }
  root_block_device {
    delete_on_termination = true
    encrypted = true
  }
  private_ip = var.lte_dns_server_ip_1
}

resource "aws_instance" "lte-dns-b" {
  ami = "ami-0f846ea6472ae64f0"
  instance_type = "c5a.xlarge"
  vpc_security_group_ids = [aws_security_group.dns-server-sg.id]
  availability_zone = "us-west-2b"
  key_name = var.lte_vpc_key_pair
  subnet_id = aws_subnet.public-b.id
  associate_public_ip_address = true
  tags = {
    Name = "lte-dns-2"
  }
  root_block_device {
    delete_on_termination = true
    encrypted = true
  }
  private_ip = var.lte_dns_server_ip_2
}
