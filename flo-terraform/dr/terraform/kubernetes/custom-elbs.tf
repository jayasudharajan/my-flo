//// replace with output and remote state and use terraform_remote_state data source instead?
//data "aws_instances" "k8s-nodes" {
//  filter {
//    name = "tag:Name"
//    values = ["nodes.k8s.flocloud.co"]
//  }
//  filter {
//    name = "tag:KubernetesCluster"
//    values = ["k8s.flocloud.co"]
//  }
//  depends_on = ["aws_autoscaling_group.nodes-k8s-dr-flocloud-co"]
//}
//
//resource "aws_security_group" "simple-nginx-router-elb-k8s-flocloud-co" {
//  name        = "simple-nginx-router-elb.k8s.flocloud.co"
//  vpc_id      = "vpc-06cc0d1f84a509986"
//  description = "Security group for simple nginx router ELB"
//
//  tags = {
//    KubernetesCluster                       = "k8s.flocloud.co"
//    Name                                    = "simple-nginx-router-elb.k8s.flocloud.co"
//    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
//  }
//}
//
//resource "aws_security_group_rule" "simple-nginx-router-elb-egress" {
//  type              = "egress"
//  security_group_id = "${aws_security_group.simple-nginx-router-elb-k8s-flocloud-co.id}"
//  from_port         = 0
//  to_port           = 0
//  protocol          = "-1"
//  cidr_blocks       = ["0.0.0.0/0"]
//}
//
//resource "aws_security_group_rule" "http-external-simple-nginx-router-elb" {
//  type              = "ingress"
//  security_group_id = "${aws_security_group.simple-nginx-router-elb-k8s-flocloud-co.id}"
//  from_port         = 80
//  to_port           = 80
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//}
//
//resource "aws_security_group_rule" "https-external-simple-nginx-router-elb" {
//  type              = "ingress"
//  security_group_id = "${aws_security_group.simple-nginx-router-elb-k8s-flocloud-co.id}"
//  from_port         = 443
//  to_port           = 443
//  protocol          = "tcp"
//  cidr_blocks       = ["0.0.0.0/0"]
//}
//// Allows access to nodes from simple-nginx-router-elb
//resource "aws_security_group_rule" "simple-nginx-router-to-node" {
//  type                     = "ingress"
//  security_group_id        = "${aws_security_group.nodes-k8s-dr-flocloud-co.id}"
//  source_security_group_id = "${aws_security_group.simple-nginx-router-elb-k8s-flocloud-co.id}"
//  from_port                = 0
//  to_port                  = 0
//  protocol                 = "-1"
//}
//
//# Load balancer for routing
//resource "aws_elb" "simple-nginx-router-elb" {
//  name               = "simple-nginx-router-elb"
//  subnets         = ["subnet-0188c04674991f00b", "subnet-061475aca2ddc5020", "subnet-0e8ad285b261eb13b"]
//  security_groups = ["${aws_security_group.simple-nginx-router-elb-k8s-flocloud-co.id}"]
//  instances = ["${data.aws_instances.k8s-nodes.ids}"]
//  idle_timeout       = 50
//
//
//  listener {
//    instance_port     = 30808
//    instance_protocol = "http"
//    lb_port           = 80
//    lb_protocol       = "http"
//  }
//
//  listener {
//    instance_port      = 30808
//    instance_protocol  = "http"
//    lb_port            = 443
//    lb_protocol        = "https"
//    ssl_certificate_id = "arn:aws:acm:us-east-2:098786959887:certificate/4f522843-d02a-4567-95b6-70efd7967d9c"
//  }
//
//  health_check {
//    healthy_threshold   = 2
//    unhealthy_threshold = 2
//    timeout             = 3
//    target              = "HTTP:30808/ping"
//    interval            = 10
//  }
//
//  tags = {
//    Deployment                              = "dev"
//    DeploymentCode                          = "dev"
//    KubernetesCluster                       = "k8s.flocloud.co"
//    Name                                    = "simeple-nginx-router.k8s.flocloud.co"
//    Project                                 = "k8s"
//    "k8s.io/cluster-autoscaler/enabled"     = "true"
//    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
//  }
//
//}
