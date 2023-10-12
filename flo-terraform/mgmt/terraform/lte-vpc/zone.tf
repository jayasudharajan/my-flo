

data "aws_route53_zone" "flotech" {
  name         = "flotech.co."
  private_zone = false
}

resource "aws_route53_zone" "lte" {
  name    = "lte.flotech.co"
  comment = "lte.flotech.co Internal Zone - Managed by Terraform"

  vpc {
    vpc_id  = aws_vpc.lte-vpc.id
  }

  tags = {
    Name = "lte.flotech.co."
  }
}

resource "aws_route53_record" "lte-ns" {
  allow_overwrite = false
  name            = "lte.flotech.co"
  ttl             = 60
  type            = "NS"
  zone_id         = data.aws_route53_zone.flotech.zone_id

  records = [
    aws_route53_zone.lte.name_servers[0],
    aws_route53_zone.lte.name_servers[1],
    aws_route53_zone.lte.name_servers[2],
    aws_route53_zone.lte.name_servers[3]
  ]
}
