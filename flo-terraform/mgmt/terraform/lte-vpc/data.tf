data "aws_subnet_ids" "private_subnets" {
  vpc_id  = aws_vpc.lte-vpc.id

  tags    = {
    Name = "Private Subnet"
    SubnetRole = "Private"
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id  = aws_vpc.lte-vpc.id

  tags    = {
    Name = "Public Subnet"
    SubnetRole = "Public"
  }
}
