data "aws_vpc" "k8s-vpc" {
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_security_group" "api-elb-sg" {
  filter {
    name = "tag:Name"
    values = ["api-elb.oceanus.flosecurecloud.com"]
  }
}

data "aws_subnet_ids" "private-k8s-subnets" {
  filter {
    name = "tag:Name"
    values = ["private-us-west-2a", "private-us-west-2b", "private-us-west-2c"]
  }
  vpc_id = data.aws_vpc.k8s-vpc.id
}

data "aws_instances" "k8s-masters" {
  filter {
    name = "tag:Name"
    values = var.k8s_masters_instances_names
  }
}

resource "aws_elb" "k8s-api-lb" {
  name = "k8s-api-lb"
  internal = true
  subnets = data.aws_subnet_ids.private-k8s-subnets.ids
  security_groups = [data.aws_security_group.api-elb-sg.id]
  listener {
    instance_port = 443
    instance_protocol = "TCP"
    lb_port = 443
    lb_protocol = "TCP"
  }
  health_check {
    healthy_threshold = 10
    interval = 30
    target = "SSL:443"
    timeout = 5
    unhealthy_threshold = 2
  }
  instances = data.aws_instances.k8s-masters.ids
}