resource "aws_vpc_endpoint" "proxy_s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.us-west-2.s3"
}

resource "aws_vpc_endpoint_route_table_association" "proxy_rt_assc_s3" {
  vpc_endpoint_id   = aws_vpc_endpoint.proxy_s3.id

  for_each          = data.aws_route_tables.private_rts.ids
  route_table_id    = each.value
}
