data "aws_nat_gateway" "k8s_natgw" {
  id = "${var.global["natgatewayId"]}"
}

data "aws_security_group" "elb" {
  tags {
    Name = "api-elb.${var.global["clusterName"]}"
  }
}

resource "aws_security_group_rule" "allow_all" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["${data.aws_nat_gateway.k8s_natgw.public_ip}/32"]
  security_group_id = "${data.aws_security_group.elb.id}"
  description = "NATGW IP to gitlabrunner access for deployment process "
}
