resource "aws_route" "route-private-natgw-2a" {
  route_table_id          = aws_route_table.rt-private-2a.id
  nat_gateway_id          = aws_nat_gateway.nat-gateway-2a.id
  destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route" "route-private-natgw-2b" {
  route_table_id          = aws_route_table.rt-private-2b.id
  nat_gateway_id          = aws_nat_gateway.nat-gateway-2b.id
  destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route" "route-private-natgw-2c" {
  route_table_id          = aws_route_table.rt-private-2c.id
  nat_gateway_id          = aws_nat_gateway.nat-gateway-2c.id
  destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route" "route-private-peer-odt-2a" {
  route_table_id          = aws_route_table.rt-private-2a.id
  destination_cidr_block  = data.aws_vpc.odt_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.odt-peer-to-ltc.id
}

resource "aws_route" "route-private-peer-odt-2b" {
  route_table_id          = aws_route_table.rt-private-2b.id
  destination_cidr_block  = data.aws_vpc.odt_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.odt-peer-to-ltc.id
}

resource "aws_route" "route-private-peer-odt-2c" {
  route_table_id          = aws_route_table.rt-private-2c.id
  destination_cidr_block  = data.aws_vpc.odt_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.odt-peer-to-ltc.id
}
