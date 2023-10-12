resource "aws_vpc" "lte-vpc" {
  cidr_block = "10.230.0.0/16"

  tags = {
    Name = "lte-vpc"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_private_subnet_a
  availability_zone = "us-west-2a"

  tags = {
    Name = "Private Subnet"
    SubnetRole = "Private"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_private_subnet_b
  availability_zone = "us-west-2b"

  tags = {
    Name = "Private Subnet"
    SubnetRole = "Private"
  }
}

resource "aws_subnet" "private-c" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_private_subnet_c
  availability_zone = "us-west-2c"

  tags = {
    Name = "Private Subnet"
    SubnetRole = "Private"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_public_subnet_a
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public Subnet"
    SubnetRole = "Public"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_public_subnet_b
  availability_zone = "us-west-2b"

  tags = {
    Name = "Public Subnet"
    SubnetRole = "Public"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id     = aws_vpc.lte-vpc.id
  cidr_block = var.lte_public_subnet_c
  availability_zone = "us-west-2c"

  tags = {
    Name = "Public Subnet"
    SubnetRole = "Public"
  }
}

resource "aws_route_table" "rt-private-2a" {
  vpc_id     = aws_vpc.lte-vpc.id

  tags = {
    Name = "rt-private-2a"
    SubnetRole = "Private"
  }
}

resource "aws_route_table" "rt-private-2b" {
  vpc_id     = aws_vpc.lte-vpc.id

  tags = {
    Name = "rt-private-2b"
    SubnetRole = "Private"
  }
}

resource "aws_route_table" "rt-private-2c" {
  vpc_id     = aws_vpc.lte-vpc.id

  tags = {
    Name = "rt-private-2c"
    SubnetRole = "Private"
  }
}

resource "aws_route_table_association" "rt-assoc-private-2a" {
  subnet_id = aws_subnet.private-a.id
  route_table_id = aws_route_table.rt-private-2a.id
}

resource "aws_route_table_association" "rt-assoc-private-2b" {
  subnet_id = aws_subnet.private-b.id
  route_table_id = aws_route_table.rt-private-2b.id
}

resource "aws_route_table_association" "rt-assoc-private-2c" {
  subnet_id = aws_subnet.private-c.id
  route_table_id = aws_route_table.rt-private-2c.id
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.lte-vpc.id
  amazon_side_asn = "64512"
  tags = {
    Name = "att-lte-vpn-vpg"
  }
}

resource "aws_eip" "public-a" {
  vpc      = true
}

resource "aws_eip" "public-b" {
  vpc     = true
}

resource "aws_eip" "public-c" {
  vpc     = true
}

resource "aws_nat_gateway" "nat-gateway-2a" {
  allocation_id = aws_eip.public-a.id
  subnet_id = aws_subnet.public-a.id
  tags = {
    Name = "nat-gateway-2a"
  }
}

resource "aws_nat_gateway" "nat-gateway-2b" {
  allocation_id = aws_eip.public-b.id
  subnet_id = aws_subnet.public-b.id
  tags = {
    Name = "nat-gateway-2b"
  }
}

resource "aws_nat_gateway" "nat-gateway-2c" {
  allocation_id = aws_eip.public-c.id
  subnet_id = aws_subnet.public-c.id
  tags = {
    Name = "nat-gateway-2c"
  }
}
