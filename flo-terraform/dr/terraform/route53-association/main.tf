data "aws_route53_zone" "dev_k8s" {
  name         = "dev.flocloud.co."
  private_zone = true
}


resource "aws_route53_zone_association" "k8s_private_zone" {
  zone_id = "${data.aws_route53_zone.dev_k8s.zone_id}"
  vpc_id  = "${var.aws["vpcId"]}"
}

output "name" {
  value = "${data.aws_route53_zone.dev_k8s.zone_id}"
}
