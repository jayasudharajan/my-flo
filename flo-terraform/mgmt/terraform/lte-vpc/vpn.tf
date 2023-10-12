resource "aws_customer_gateway" "cgw-att-lte-vpn-cg-dc1" {
  bgp_asn     = 36180
  ip_address  = "208.184.161.98"
  type        = "ipsec.1"

  tags = {
    Name = "att-lte-vpn-cg-dc1"
  }
}

resource "aws_customer_gateway" "cgw-att-lte-vpn-cg-dc2" {
  bgp_asn     = 36180
  ip_address  = "208.184.162.98"
  type        = "ipsec.1"

  tags = {
    Name = "att-lte-vpn-cg-dc2"
  }
}

resource "aws_vpn_gateway" "vgw-att-lte-vpn-vpg" {
  vpc_id     = aws_vpc.lte-vpc.id

  tags = {
    Name = "att-lte-vpn-vpg"
  }
}

resource "aws_vpn_connection" "vpn-att-lte-vpn-dc1" {
  vpn_gateway_id        = aws_vpn_gateway.vgw-att-lte-vpn-vpg.id
  customer_gateway_id   = aws_customer_gateway.cgw-att-lte-vpn-cg-dc1.id
  type                  = "ipsec.1"
  static_routes_only    = false

  tags = {
    Name = "att-lte-vpn-dc1"
  }
}

resource "aws_vpn_connection" "vpn-att-lte-vpn-dc2" {
  vpn_gateway_id        = aws_vpn_gateway.vgw-att-lte-vpn-vpg.id
  customer_gateway_id   = aws_customer_gateway.cgw-att-lte-vpn-cg-dc2.id
  type                  = "ipsec.1"
  static_routes_only    = false

  tags = {
    Name = "att-lte-vpn-dc2"
  }
}

resource "aws_vpn_gateway_route_propagation" "vgw-route-private-2a" {
  vpn_gateway_id = aws_vpn_gateway.vgw-att-lte-vpn-vpg.id
  route_table_id = aws_route_table.rt-private-2a.id
}

resource "aws_vpn_gateway_route_propagation" "vgw-route-private-2b" {
  vpn_gateway_id = aws_vpn_gateway.vgw-att-lte-vpn-vpg.id
  route_table_id = aws_route_table.rt-private-2b.id
}

resource "aws_vpn_gateway_route_propagation" "vgw-route-private-2c" {
  vpn_gateway_id = aws_vpn_gateway.vgw-att-lte-vpn-vpg.id
  route_table_id = aws_route_table.rt-private-2c.id
}
