data "aws_vpc" "odt_vpc" {
  tags = {
    Name = "odt-vpc"
  }
}


resource "aws_vpc_peering_connection" "odt-peer-to-ltc" {
  peer_vpc_id = data.aws_vpc.odt_vpc.id
  vpc_id = aws_vpc.lte-vpc.id
  auto_accept = true
  tags = {
    Name = "odt-peer-to-ltc"
  }
}

# Routes to lte

resource "aws_route" "odt2lte" {
  route_table_id = data.aws_vpc.odt_vpc.main_route_table_id
  destination_cidr_block = aws_vpc.lte-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.odt-peer-to-ltc.id
}


# Routes to odt

resource "aws_route" "lte2odt" {
  route_table_id = aws_vpc.lte-vpc.main_route_table_id
  destination_cidr_block = data.aws_vpc.odt_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.odt-peer-to-ltc.id
}
