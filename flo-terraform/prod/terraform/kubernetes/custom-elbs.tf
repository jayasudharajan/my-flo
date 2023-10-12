// replace with output and remote state and use terraform_remote_state data source instead?
data "aws_instances" "k8s-nodes" {
  filter {
    name = "tag:Name"
    values = ["nodes.oceanus.flosecurecloud.com"]
  }
  filter {
    name = "tag:KubernetesCluster"
    values = ["oceanus.flosecurecloud.com"]
  }
}



resource "aws_security_group" "simple-nginx-router-elb-oceanus-flosecurecloud-com" {
  name        = "simple-nginx-router-elb.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for simple nginx router ELB"

  tags = {
    KubernetesCluster                       = "oceanus.flosecurecloud.com"
    Name                                    = "simple-nginx-router-elb.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group_rule" "simple-nginx-router-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.simple-nginx-router-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http-external-simple-nginx-router-elb" {
  type              = "ingress"
  security_group_id = "${aws_security_group.simple-nginx-router-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https-external-simple-nginx-router-elb" {
  type              = "ingress"
  security_group_id = "${aws_security_group.simple-nginx-router-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

// Allows access to nodes from simple-nginx-router-elb
resource "aws_security_group_rule" "simple-nginx-router-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.simple-nginx-router-elb-oceanus-flosecurecloud-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

# Load balancer for routing
resource "aws_elb" "simple-nginx-router-elb" {
  name               = "simple-nginx-router-elb"
  subnets         = ["subnet-087c9074a9692cd91", "subnet-0d67fd546322de9a8", "subnet-0dbb3614bcfdb9a8c"]
  security_groups = ["${aws_security_group.simple-nginx-router-elb-oceanus-flosecurecloud-com.id}"]
  instances = ["${data.aws_instances.k8s-nodes.ids}"]


  listener {
    instance_port     = 30808
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 30808
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:acm:us-west-2:617288038711:certificate/49f4de9f-74a3-41bc-8808-e2558c45999b"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:30808/ping"
    interval            = 10
  }

  tags = {
    Deployment                              = "prod"
    DeploymentCode                          = "prod"
    KubernetesCluster                       = "oceanus.flosecurecloud.com"
    Name                                    = "simeple-nginx-router.oceanus.flosecurecloud.com"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}
