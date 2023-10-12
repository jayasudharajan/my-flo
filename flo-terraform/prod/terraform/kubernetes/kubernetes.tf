locals = {
  bastion_autoscaling_group_ids = ["${aws_autoscaling_group.bastions-oceanus-flosecurecloud-com.id}"]
  bastion_security_group_ids    = ["${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"]
  bastions_role_arn             = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.arn}"
  bastions_role_name            = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.name}"
  cluster_name                  = "oceanus.flosecurecloud.com"
  master_autoscaling_group_ids  = ["${aws_autoscaling_group.master-us-west-2a-masters-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.master-us-west-2b-masters-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.master-us-west-2c-masters-oceanus-flosecurecloud-com.id}"]
  master_security_group_ids     = ["${aws_security_group.masters-oceanus-flosecurecloud-com.id}"]
  masters_role_arn              = "${aws_iam_role.masters-oceanus-flosecurecloud-com.arn}"
  masters_role_name             = "${aws_iam_role.masters-oceanus-flosecurecloud-com.name}"
  node_autoscaling_group_ids    = ["${aws_autoscaling_group.gitlabrunner-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.nodes-oceanus-flosecurecloud-com.id}"]
  node_security_group_ids       = ["${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"]
  node_subnet_ids               = ["subnet-041686fbee73e472c", "subnet-0c006fb43c7ca280a", "subnet-0d238984537477ecf"]
  nodes_role_arn                = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.arn}"
  nodes_role_name               = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.name}"
  region                        = "us-west-2"
  subnet_ids                    = ["subnet-041686fbee73e472c", "subnet-087c9074a9692cd91", "subnet-0c006fb43c7ca280a", "subnet-0d238984537477ecf", "subnet-0d67fd546322de9a8", "subnet-0dbb3614bcfdb9a8c"]
  subnet_private-us-west-2a_id  = "subnet-0d238984537477ecf"
  subnet_private-us-west-2b_id  = "subnet-041686fbee73e472c"
  subnet_private-us-west-2c_id  = "subnet-0c006fb43c7ca280a"
  subnet_public-us-west-2a_id   = "subnet-087c9074a9692cd91"
  subnet_public-us-west-2b_id   = "subnet-0dbb3614bcfdb9a8c"
  subnet_public-us-west-2c_id   = "subnet-0d67fd546322de9a8"
  vpc_id                        = "vpc-0a9dcce1bf2d29502"
}

output "bastion_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.bastions-oceanus-flosecurecloud-com.id}"]
}

output "bastion_security_group_ids" {
  value = ["${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"]
}

output "bastions_role_arn" {
  value = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.arn}"
}

output "bastions_role_name" {
  value = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.name}"
}

output "cluster_name" {
  value = "oceanus.flosecurecloud.com"
}

output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-us-west-2a-masters-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.master-us-west-2b-masters-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.master-us-west-2c-masters-oceanus-flosecurecloud-com.id}"]
}

output "master_security_group_ids" {
  value = ["${aws_security_group.masters-oceanus-flosecurecloud-com.id}"]
}

output "masters_role_arn" {
  value = "${aws_iam_role.masters-oceanus-flosecurecloud-com.arn}"
}

output "masters_role_name" {
  value = "${aws_iam_role.masters-oceanus-flosecurecloud-com.name}"
}

output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.gitlabrunner-oceanus-flosecurecloud-com.id}", "${aws_autoscaling_group.nodes-oceanus-flosecurecloud-com.id}"]
}

output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"]
}

output "node_subnet_ids" {
  value = ["subnet-041686fbee73e472c", "subnet-0c006fb43c7ca280a", "subnet-0d238984537477ecf"]
}

output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.arn}"
}

output "nodes_role_name" {
  value = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.name}"
}

output "region" {
  value = "us-west-2"
}

output "subnet_ids" {
  value = ["subnet-041686fbee73e472c", "subnet-087c9074a9692cd91", "subnet-0c006fb43c7ca280a", "subnet-0d238984537477ecf", "subnet-0d67fd546322de9a8", "subnet-0dbb3614bcfdb9a8c"]
}

output "subnet_private-us-west-2a_id" {
  value = "subnet-0d238984537477ecf"
}

output "subnet_private-us-west-2b_id" {
  value = "subnet-041686fbee73e472c"
}

output "subnet_private-us-west-2c_id" {
  value = "subnet-0c006fb43c7ca280a"
}

output "subnet_public-us-west-2a_id" {
  value = "subnet-087c9074a9692cd91"
}

output "subnet_public-us-west-2b_id" {
  value = "subnet-0dbb3614bcfdb9a8c"
}

output "subnet_public-us-west-2c_id" {
  value = "subnet-0d67fd546322de9a8"
}

output "vpc_id" {
  value = "vpc-0a9dcce1bf2d29502"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_autoscaling_attachment" "bastions-oceanus-flosecurecloud-com" {
  elb                    = "${aws_elb.bastion-oceanus-flosecurecloud-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.bastions-oceanus-flosecurecloud-com.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2a-masters-oceanus-flosecurecloud-com" {
  elb                    = "${aws_elb.api-oceanus-flosecurecloud-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2a-masters-oceanus-flosecurecloud-com.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2b-masters-oceanus-flosecurecloud-com" {
  elb                    = "${aws_elb.api-oceanus-flosecurecloud-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2b-masters-oceanus-flosecurecloud-com.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2c-masters-oceanus-flosecurecloud-com" {
  elb                    = "${aws_elb.api-oceanus-flosecurecloud-com.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2c-masters-oceanus-flosecurecloud-com.id}"
}

resource "aws_autoscaling_group" "bastions-oceanus-flosecurecloud-com" {
  name                 = "bastions.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.bastions-oceanus-flosecurecloud-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-087c9074a9692cd91", "subnet-0dbb3614bcfdb9a8c", "subnet-0d67fd546322de9a8"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "bastions.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "bastions"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/bastion"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "gitlabrunner-oceanus-flosecurecloud-com" {
  name                 = "gitlabrunner.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.gitlabrunner-oceanus-flosecurecloud-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0d238984537477ecf", "subnet-041686fbee73e472c", "subnet-0c006fb43c7ca280a"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "gitlabrunner.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "gitlabrunner"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2a-masters-oceanus-flosecurecloud-com" {
  name                 = "master-us-west-2a.masters.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.master-us-west-2a-masters-oceanus-flosecurecloud-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0d238984537477ecf"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2a.masters.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2b-masters-oceanus-flosecurecloud-com" {
  name                 = "master-us-west-2b.masters.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.master-us-west-2b-masters-oceanus-flosecurecloud-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-041686fbee73e472c"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2b.masters.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2c-masters-oceanus-flosecurecloud-com" {
  name                 = "master-us-west-2c.masters.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.master-us-west-2c-masters-oceanus-flosecurecloud-com.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0c006fb43c7ca280a"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2c.masters.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "nodes-oceanus-flosecurecloud-com" {
  name                 = "nodes.oceanus.flosecurecloud.com"
  launch_configuration = "${aws_launch_configuration.nodes-oceanus-flosecurecloud-com.id}"
  max_size             = 15
  min_size             = 9
  vpc_zone_identifier  = ["subnet-0d238984537477ecf", "subnet-041686fbee73e472c", "subnet-0c006fb43c7ca280a"]

  tag = {
    key                 = "Deployment"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "nodes.oceanus.flosecurecloud.com"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s-prod"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "nodes"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/oceanus.flosecurecloud.com"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_ebs_volume" "a-etcd-events-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "a.etcd-events.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/events"                               = "a/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_ebs_volume" "a-etcd-main-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "a.etcd-main.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/main"                                 = "a/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_ebs_volume" "b-etcd-events-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "b.etcd-events.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/events"                               = "b/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_ebs_volume" "b-etcd-main-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "b.etcd-main.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/main"                                 = "b/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_ebs_volume" "c-etcd-events-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "c.etcd-events.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/events"                               = "c/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_ebs_volume" "c-etcd-main-oceanus-flosecurecloud-com" {
  availability_zone = "us-west-2c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "c.etcd-main.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "k8s.io/etcd/main"                                 = "c/a,b,c"
    "k8s.io/role/master"                               = "1"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_elb" "api-oceanus-flosecurecloud-com" {
  name = "api-oceanus-flosecureclou-a2a8m1"

  listener = {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.api-elb-oceanus-flosecurecloud-com.id}"]
  subnets         = ["subnet-087c9074a9692cd91", "subnet-0d67fd546322de9a8", "subnet-0dbb3614bcfdb9a8c"]

  health_check = {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "api.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_elb" "bastion-oceanus-flosecurecloud-com" {
  name = "bastion-oceanus-flosecure-omjp5j"

  listener = {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.bastion-elb-oceanus-flosecurecloud-com.id}"]
  subnets         = ["subnet-087c9074a9692cd91", "subnet-0d67fd546322de9a8", "subnet-0dbb3614bcfdb9a8c"]

  health_check = {
    target              = "TCP:22"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    Deployment                                         = "prod"
    DeploymentCode                                     = "prod"
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "bastion.oceanus.flosecurecloud.com"
    Project                                            = "k8s-prod"
    "k8s.io/cluster-autoscaler/enabled"                = "true"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_iam_instance_profile" "bastions-oceanus-flosecurecloud-com" {
  name = "bastions.oceanus.flosecurecloud.com"
  role = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.name}"
}

resource "aws_iam_instance_profile" "masters-oceanus-flosecurecloud-com" {
  name = "masters.oceanus.flosecurecloud.com"
  role = "${aws_iam_role.masters-oceanus-flosecurecloud-com.name}"
}

resource "aws_iam_instance_profile" "nodes-oceanus-flosecurecloud-com" {
  name = "nodes.oceanus.flosecurecloud.com"
  role = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.name}"
}

resource "aws_iam_role" "bastions-oceanus-flosecurecloud-com" {
  name               = "bastions.oceanus.flosecurecloud.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_bastions.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role" "masters-oceanus-flosecurecloud-com" {
  name               = "masters.oceanus.flosecurecloud.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role" "nodes-oceanus-flosecurecloud-com" {
  name               = "nodes.oceanus.flosecurecloud.com"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role_policy" "additional-nodes-oceanus-flosecurecloud-com" {
  name   = "additional.nodes.oceanus.flosecurecloud.com"
  role   = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_additional.nodes.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role_policy" "bastions-oceanus-flosecurecloud-com" {
  name   = "bastions.oceanus.flosecurecloud.com"
  role   = "${aws_iam_role.bastions-oceanus-flosecurecloud-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_bastions.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role_policy" "masters-oceanus-flosecurecloud-com" {
  name   = "masters.oceanus.flosecurecloud.com"
  role   = "${aws_iam_role.masters-oceanus-flosecurecloud-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_iam_role_policy" "nodes-oceanus-flosecurecloud-com" {
  name   = "nodes.oceanus.flosecurecloud.com"
  role   = "${aws_iam_role.nodes-oceanus-flosecurecloud-com.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.oceanus.flosecurecloud.com_policy")}"
}

resource "aws_key_pair" "kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815" {
  key_name   = "kubernetes.oceanus.flosecurecloud.com-87:d8:bd:bd:5d:54:3d:6c:fc:93:87:88:25:fb:48:15"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.oceanus.flosecurecloud.com-87d8bdbd5d543d6cfc93878825fb4815_public_key")}"
}

resource "aws_launch_configuration" "bastions-oceanus-flosecurecloud-com" {
  name_prefix                 = "bastions.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t3.small"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.bastions-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = true

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 32
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "gitlabrunner-oceanus-flosecurecloud-com" {
  name_prefix                 = "gitlabrunner.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "m5.large"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_gitlabrunner.oceanus.flosecurecloud.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "master-us-west-2a-masters-oceanus-flosecurecloud-com" {
  name_prefix                 = "master-us-west-2a.masters.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.large"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.masters-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2a.masters.oceanus.flosecurecloud.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "master-us-west-2b-masters-oceanus-flosecurecloud-com" {
  name_prefix                 = "master-us-west-2b.masters.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.large"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.masters-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2b.masters.oceanus.flosecurecloud.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "master-us-west-2c-masters-oceanus-flosecurecloud-com" {
  name_prefix                 = "master-us-west-2c.masters.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.large"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.masters-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2c.masters.oceanus.flosecurecloud.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "nodes-oceanus-flosecurecloud-com" {
  name_prefix                 = "nodes.oceanus.flosecurecloud.com-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.2xlarge"
  key_name                    = "${aws_key_pair.kubernetes-oceanus-flosecurecloud-com-87d8bdbd5d543d6cfc93878825fb4815.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-oceanus-flosecurecloud-com.id}"
  security_groups             = ["${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.oceanus.flosecurecloud.com_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 128
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_route53_record" "api-oceanus-flosecurecloud-com" {
  name = "api.oceanus.flosecurecloud.com"
  type = "A"

  alias = {
    name                   = "${aws_elb.api-oceanus-flosecurecloud-com.dns_name}"
    zone_id                = "${aws_elb.api-oceanus-flosecurecloud-com.zone_id}"
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/Z29QURVJDHEFYX"
}

resource "aws_route53_record" "bastion-oceanus-flosecurecloud-com" {
  name = "bastion.oceanus.flosecurecloud.com"
  type = "A"

  alias = {
    name                   = "${aws_elb.bastion-oceanus-flosecurecloud-com.dns_name}"
    zone_id                = "${aws_elb.bastion-oceanus-flosecurecloud-com.zone_id}"
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/Z29QURVJDHEFYX"
}

resource "aws_security_group" "api-elb-oceanus-flosecurecloud-com" {
  name        = "api-elb.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for api ELB"

  tags = {
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "api-elb.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_security_group" "bastion-elb-oceanus-flosecurecloud-com" {
  name        = "bastion-elb.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for bastion ELB"

  tags = {
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "bastion-elb.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_security_group" "bastion-oceanus-flosecurecloud-com" {
  name        = "bastion.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for bastion"

  tags = {
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "bastion.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_security_group" "masters-oceanus-flosecurecloud-com" {
  name        = "masters.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "masters.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_security_group" "nodes-oceanus-flosecurecloud-com" {
  name        = "nodes.oceanus.flosecurecloud.com"
  vpc_id      = "vpc-0a9dcce1bf2d29502"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                                  = "oceanus.flosecurecloud.com"
    Name                                               = "nodes.oceanus.flosecurecloud.com"
    "kubernetes.io/cluster/oceanus.flosecurecloud.com" = "owned"
  }
}

resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "api-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.api-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-to-master-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion-to-node-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "https-api-elb-108-60-116-94--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["108.60.116.94/32"]
}

resource "aws_security_group_rule" "https-elb-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.api-elb-oceanus-flosecurecloud-com.id}"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "icmp-pmtu-api-elb-108-60-116-94--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 3
  to_port           = 4
  protocol          = "icmp"
  cidr_blocks       = ["108.60.116.94/32"]
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-to-master-protocol-ipip" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "4"
}

resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-2382-4001" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 2382
  to_port                  = 4001
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.nodes-oceanus-flosecurecloud-com.id}"
  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}

resource "aws_security_group_rule" "ssh-elb-to-bastion" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.bastion-oceanus-flosecurecloud-com.id}"
  source_security_group_id = "${aws_security_group.bastion-elb-oceanus-flosecurecloud-com.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "ssh-external-to-bastion-elb-108-60-116-94--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.bastion-elb-oceanus-flosecurecloud-com.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["108.60.116.94/32"]
}

terraform = {
  required_version = ">= 0.9.3"
}
