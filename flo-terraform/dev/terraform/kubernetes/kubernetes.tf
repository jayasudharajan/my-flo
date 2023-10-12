locals = {
  bastion_autoscaling_group_ids = ["${aws_autoscaling_group.bastions-k8s-flocloud-co.id}"]
  bastion_security_group_ids    = ["${aws_security_group.bastion-k8s-flocloud-co.id}"]
  bastions_role_arn             = "${aws_iam_role.bastions-k8s-flocloud-co.arn}"
  bastions_role_name            = "${aws_iam_role.bastions-k8s-flocloud-co.name}"
  cluster_name                  = "k8s.flocloud.co"
  master_autoscaling_group_ids  = ["${aws_autoscaling_group.master-us-west-2a-masters-k8s-flocloud-co.id}", "${aws_autoscaling_group.master-us-west-2b-masters-k8s-flocloud-co.id}", "${aws_autoscaling_group.master-us-west-2c-masters-k8s-flocloud-co.id}"]
  master_security_group_ids     = ["${aws_security_group.masters-k8s-flocloud-co.id}"]
  masters_role_arn              = "${aws_iam_role.masters-k8s-flocloud-co.arn}"
  masters_role_name             = "${aws_iam_role.masters-k8s-flocloud-co.name}"
  node_autoscaling_group_ids    = ["${aws_autoscaling_group.gitlabrunner-firmware-k8s-flocloud-co.id}", "${aws_autoscaling_group.gitlabrunner-k8s-flocloud-co.id}", "${aws_autoscaling_group.nodes-k8s-flocloud-co.id}", "${aws_autoscaling_group.peering-node-k8s-flocloud-co.id}"]
  node_security_group_ids       = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
  node_subnet_ids               = ["subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c", "subnet-07107f3cb4c7e23a0", "subnet-095108c660f0b2e65"]
  nodes_role_arn                = "${aws_iam_role.nodes-k8s-flocloud-co.arn}"
  nodes_role_name               = "${aws_iam_role.nodes-k8s-flocloud-co.name}"
  region                        = "us-west-2"
  subnet_ids                    = ["subnet-0188c04674991f00b", "subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c", "subnet-061475aca2ddc5020", "subnet-07107f3cb4c7e23a0", "subnet-095108c660f0b2e65", "subnet-0e8ad285b261eb13b"]
  subnet_peering-us-west-2a_id  = "subnet-095108c660f0b2e65"
  subnet_private-us-west-2a_id  = "subnet-07107f3cb4c7e23a0"
  subnet_private-us-west-2b_id  = "subnet-01b3a1b42ad1b0b22"
  subnet_private-us-west-2c_id  = "subnet-041a0b132a559d04c"
  subnet_public-us-west-2a_id   = "subnet-061475aca2ddc5020"
  subnet_public-us-west-2b_id   = "subnet-0188c04674991f00b"
  subnet_public-us-west-2c_id   = "subnet-0e8ad285b261eb13b"
  vpc_id                        = "vpc-06cc0d1f84a509986"
}

output "bastion_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.bastions-k8s-flocloud-co.id}"]
}

output "bastion_security_group_ids" {
  value = ["${aws_security_group.bastion-k8s-flocloud-co.id}"]
}

output "bastions_role_arn" {
  value = "${aws_iam_role.bastions-k8s-flocloud-co.arn}"
}

output "bastions_role_name" {
  value = "${aws_iam_role.bastions-k8s-flocloud-co.name}"
}

output "cluster_name" {
  value = "k8s.flocloud.co"
}

output "master_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.master-us-west-2a-masters-k8s-flocloud-co.id}", "${aws_autoscaling_group.master-us-west-2b-masters-k8s-flocloud-co.id}", "${aws_autoscaling_group.master-us-west-2c-masters-k8s-flocloud-co.id}"]
}

output "master_security_group_ids" {
  value = ["${aws_security_group.masters-k8s-flocloud-co.id}"]
}

output "masters_role_arn" {
  value = "${aws_iam_role.masters-k8s-flocloud-co.arn}"
}

output "masters_role_name" {
  value = "${aws_iam_role.masters-k8s-flocloud-co.name}"
}

output "node_autoscaling_group_ids" {
  value = ["${aws_autoscaling_group.gitlabrunner-firmware-k8s-flocloud-co.id}", "${aws_autoscaling_group.gitlabrunner-k8s-flocloud-co.id}", "${aws_autoscaling_group.nodes-k8s-flocloud-co.id}", "${aws_autoscaling_group.peering-node-k8s-flocloud-co.id}"]
}

output "node_security_group_ids" {
  value = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
}

output "node_subnet_ids" {
  value = ["subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c", "subnet-07107f3cb4c7e23a0", "subnet-095108c660f0b2e65"]
}

output "nodes_role_arn" {
  value = "${aws_iam_role.nodes-k8s-flocloud-co.arn}"
}

output "nodes_role_name" {
  value = "${aws_iam_role.nodes-k8s-flocloud-co.name}"
}

output "region" {
  value = "us-west-2"
}

output "subnet_ids" {
  value = ["subnet-0188c04674991f00b", "subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c", "subnet-061475aca2ddc5020", "subnet-07107f3cb4c7e23a0", "subnet-095108c660f0b2e65", "subnet-0e8ad285b261eb13b"]
}

output "subnet_peering-us-west-2a_id" {
  value = "subnet-095108c660f0b2e65"
}

output "subnet_private-us-west-2a_id" {
  value = "subnet-07107f3cb4c7e23a0"
}

output "subnet_private-us-west-2b_id" {
  value = "subnet-01b3a1b42ad1b0b22"
}

output "subnet_private-us-west-2c_id" {
  value = "subnet-041a0b132a559d04c"
}

output "subnet_public-us-west-2a_id" {
  value = "subnet-061475aca2ddc5020"
}

output "subnet_public-us-west-2b_id" {
  value = "subnet-0188c04674991f00b"
}

output "subnet_public-us-west-2c_id" {
  value = "subnet-0e8ad285b261eb13b"
}

output "vpc_id" {
  value = "vpc-06cc0d1f84a509986"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_autoscaling_attachment" "bastions-k8s-flocloud-co" {
  elb                    = "${aws_elb.bastion-k8s-flocloud-co.id}"
  autoscaling_group_name = "${aws_autoscaling_group.bastions-k8s-flocloud-co.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2a-masters-k8s-flocloud-co" {
  elb                    = "${aws_elb.api-k8s-flocloud-co.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2a-masters-k8s-flocloud-co.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2b-masters-k8s-flocloud-co" {
  elb                    = "${aws_elb.api-k8s-flocloud-co.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2b-masters-k8s-flocloud-co.id}"
}

resource "aws_autoscaling_attachment" "master-us-west-2c-masters-k8s-flocloud-co" {
  elb                    = "${aws_elb.api-k8s-flocloud-co.id}"
  autoscaling_group_name = "${aws_autoscaling_group.master-us-west-2c-masters-k8s-flocloud-co.id}"
}

resource "aws_autoscaling_group" "bastions-k8s-flocloud-co" {
  name                 = "bastions.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.bastions-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-061475aca2ddc5020", "subnet-0188c04674991f00b", "subnet-0e8ad285b261eb13b"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "bastions.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
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
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "gitlabrunner-firmware-k8s-flocloud-co" {
  name                 = "gitlabrunner-firmware.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.gitlabrunner-firmware-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-07107f3cb4c7e23a0", "subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "gitlabrunner-firmware.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "gitlabrunner-firmware"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "gitlabrunner-k8s-flocloud-co" {
  name                 = "gitlabrunner.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.gitlabrunner-k8s-flocloud-co.id}"
  max_size             = 2
  min_size             = 2
  vpc_zone_identifier  = ["subnet-07107f3cb4c7e23a0", "subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "gitlabrunner.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
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
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2a-masters-k8s-flocloud-co" {
  name                 = "master-us-west-2a.masters.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.master-us-west-2a-masters-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-07107f3cb4c7e23a0"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2a.masters.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2b-masters-k8s-flocloud-co" {
  name                 = "master-us-west-2b.masters.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.master-us-west-2b-masters-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-01b3a1b42ad1b0b22"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2b.masters.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "master-us-west-2c-masters-k8s-flocloud-co" {
  name                 = "master-us-west-2c.masters.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.master-us-west-2c-masters-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-041a0b132a559d04c"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "master-us-west-2c.masters.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/master"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "nodes-k8s-flocloud-co" {
  name                 = "nodes.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.nodes-k8s-flocloud-co.id}"
  max_size             = 11
  min_size             = 10
  vpc_zone_identifier  = ["subnet-07107f3cb4c7e23a0", "subnet-01b3a1b42ad1b0b22", "subnet-041a0b132a559d04c"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "nodes.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
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
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_autoscaling_group" "peering-node-k8s-flocloud-co" {
  name                 = "peering-node.k8s.flocloud.co"
  launch_configuration = "${aws_launch_configuration.peering-node-k8s-flocloud-co.id}"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = ["subnet-095108c660f0b2e65"]

  tag = {
    key                 = "Deployment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "DeploymentCode"
    value               = "dev"
    propagate_at_launch = true
  }

  tag = {
    key                 = "KubernetesCluster"
    value               = "k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Name"
    value               = "peering-node.k8s.flocloud.co"
    propagate_at_launch = true
  }

  tag = {
    key                 = "Project"
    value               = "k8s"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup"
    value               = "peering-node"
    propagate_at_launch = true
  }

  tag = {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }

  tag = {
    key                 = "kubernetes.io/cluster/k8s.flocloud.co"
    value               = "owned"
    propagate_at_launch = true
  }

  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
}

resource "aws_ebs_volume" "a-etcd-events-k8s-flocloud-co" {
  availability_zone = "us-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "a.etcd-events.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/events"                    = "a/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_ebs_volume" "a-etcd-main-k8s-flocloud-co" {
  availability_zone = "us-west-2a"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "a.etcd-main.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/main"                      = "a/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_ebs_volume" "b-etcd-events-k8s-flocloud-co" {
  availability_zone = "us-west-2b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "b.etcd-events.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/events"                    = "b/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_ebs_volume" "b-etcd-main-k8s-flocloud-co" {
  availability_zone = "us-west-2b"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "b.etcd-main.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/main"                      = "b/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_ebs_volume" "c-etcd-events-k8s-flocloud-co" {
  availability_zone = "us-west-2c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "c.etcd-events.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/events"                    = "c/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_ebs_volume" "c-etcd-main-k8s-flocloud-co" {
  availability_zone = "us-west-2c"
  size              = 20
  type              = "gp2"
  encrypted         = true

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "c.etcd-main.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/etcd/main"                      = "c/a,b,c"
    "k8s.io/role/master"                    = "1"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_elb" "api-k8s-flocloud-co" {
  name = "api-k8s-flocloud-co-ictilp"

  listener = {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.api-elb-k8s-flocloud-co.id}"]
  subnets         = ["subnet-0188c04674991f00b", "subnet-061475aca2ddc5020", "subnet-0e8ad285b261eb13b"]

  health_check = {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "api.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_elb" "bastion-k8s-flocloud-co" {
  name = "bastion-k8s-flocloud-co-btdm7r"

  listener = {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }

  security_groups = ["${aws_security_group.bastion-elb-k8s-flocloud-co.id}"]
  subnets         = ["subnet-0188c04674991f00b", "subnet-061475aca2ddc5020", "subnet-0e8ad285b261eb13b"]

  health_check = {
    target              = "TCP:22"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    timeout             = 5
  }

  idle_timeout = 300

  tags = {
    Deployment                              = "dev"
    DeploymentCode                          = "dev"
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "bastion.k8s.flocloud.co"
    Project                                 = "k8s"
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_iam_instance_profile" "bastions-k8s-flocloud-co" {
  name = "bastions.k8s.flocloud.co"
  role = "${aws_iam_role.bastions-k8s-flocloud-co.name}"
}

resource "aws_iam_instance_profile" "masters-k8s-flocloud-co" {
  name = "masters.k8s.flocloud.co"
  role = "${aws_iam_role.masters-k8s-flocloud-co.name}"
}

resource "aws_iam_instance_profile" "nodes-k8s-flocloud-co" {
  name = "nodes.k8s.flocloud.co"
  role = "${aws_iam_role.nodes-k8s-flocloud-co.name}"
}

resource "aws_iam_role" "bastions-k8s-flocloud-co" {
  name               = "bastions.k8s.flocloud.co"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_bastions.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role" "masters-k8s-flocloud-co" {
  name               = "masters.k8s.flocloud.co"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_masters.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role" "nodes-k8s-flocloud-co" {
  name               = "nodes.k8s.flocloud.co"
  assume_role_policy = "${file("${path.module}/data/aws_iam_role_nodes.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role_policy" "additional-nodes-k8s-flocloud-co" {
  name   = "additional.nodes.k8s.flocloud.co"
  role   = "${aws_iam_role.nodes-k8s-flocloud-co.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_additional.nodes.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role_policy" "bastions-k8s-flocloud-co" {
  name   = "bastions.k8s.flocloud.co"
  role   = "${aws_iam_role.bastions-k8s-flocloud-co.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_bastions.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role_policy" "masters-k8s-flocloud-co" {
  name   = "masters.k8s.flocloud.co"
  role   = "${aws_iam_role.masters-k8s-flocloud-co.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_masters.k8s.flocloud.co_policy")}"
}

resource "aws_iam_role_policy" "nodes-k8s-flocloud-co" {
  name   = "nodes.k8s.flocloud.co"
  role   = "${aws_iam_role.nodes-k8s-flocloud-co.name}"
  policy = "${file("${path.module}/data/aws_iam_role_policy_nodes.k8s.flocloud.co_policy")}"
}

resource "aws_key_pair" "kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae" {
  key_name   = "kubernetes.k8s.flocloud.co-c0:ef:7a:c2:73:29:ac:22:cb:bc:4c:98:38:fb:2b:ae"
  public_key = "${file("${path.module}/data/aws_key_pair_kubernetes.k8s.flocloud.co-c0ef7ac27329ac22cbbc4c9838fb2bae_public_key")}"
}

resource "aws_launch_configuration" "bastions-k8s-flocloud-co" {
  name_prefix                 = "bastions.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t2.medium"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.bastions-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.bastion-k8s-flocloud-co.id}"]
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

resource "aws_launch_configuration" "gitlabrunner-firmware-k8s-flocloud-co" {
  name_prefix                 = "gitlabrunner-firmware.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.4xlarge"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_gitlabrunner-firmware.k8s.flocloud.co_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 500
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_launch_configuration" "gitlabrunner-k8s-flocloud-co" {
  name_prefix                 = "gitlabrunner.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.xlarge"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_gitlabrunner.k8s.flocloud.co_user_data")}"

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

resource "aws_launch_configuration" "master-us-west-2a-masters-k8s-flocloud-co" {
  name_prefix                 = "master-us-west-2a.masters.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t3.medium"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.masters-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2a.masters.k8s.flocloud.co_user_data")}"

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

resource "aws_launch_configuration" "master-us-west-2b-masters-k8s-flocloud-co" {
  name_prefix                 = "master-us-west-2b.masters.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t3.medium"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.masters-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2b.masters.k8s.flocloud.co_user_data")}"

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

resource "aws_launch_configuration" "master-us-west-2c-masters-k8s-flocloud-co" {
  name_prefix                 = "master-us-west-2c.masters.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t3.medium"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.masters-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.masters-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_master-us-west-2c.masters.k8s.flocloud.co_user_data")}"

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

resource "aws_launch_configuration" "nodes-k8s-flocloud-co" {
  name_prefix                 = "nodes.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "c5.xlarge"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_nodes.k8s.flocloud.co_user_data")}"

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

resource "aws_launch_configuration" "peering-node-k8s-flocloud-co" {
  name_prefix                 = "peering-node.k8s.flocloud.co-"
  image_id                    = "ami-0f8ed4b94f5852ba5"
  instance_type               = "t3a.micro"
  key_name                    = "${aws_key_pair.kubernetes-k8s-flocloud-co-c0ef7ac27329ac22cbbc4c9838fb2bae.id}"
  iam_instance_profile        = "${aws_iam_instance_profile.nodes-k8s-flocloud-co.id}"
  security_groups             = ["${aws_security_group.nodes-k8s-flocloud-co.id}"]
  associate_public_ip_address = false
  user_data                   = "${file("${path.module}/data/aws_launch_configuration_peering-node.k8s.flocloud.co_user_data")}"

  root_block_device = {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }

  lifecycle = {
    create_before_destroy = true
  }

  enable_monitoring = false
}

resource "aws_route53_record" "api-k8s-flocloud-co" {
  name = "api.k8s.flocloud.co"
  type = "A"

  alias = {
    name                   = "${aws_elb.api-k8s-flocloud-co.dns_name}"
    zone_id                = "${aws_elb.api-k8s-flocloud-co.zone_id}"
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/Z1CQZEKQBHSJN7"
}

resource "aws_route53_record" "bastion-k8s-flocloud-co" {
  name = "bastion.k8s.flocloud.co"
  type = "A"

  alias = {
    name                   = "${aws_elb.bastion-k8s-flocloud-co.dns_name}"
    zone_id                = "${aws_elb.bastion-k8s-flocloud-co.zone_id}"
    evaluate_target_health = false
  }

  zone_id = "/hostedzone/Z1CQZEKQBHSJN7"
}

resource "aws_security_group" "api-elb-k8s-flocloud-co" {
  name        = "api-elb.k8s.flocloud.co"
  vpc_id      = "vpc-06cc0d1f84a509986"
  description = "Security group for api ELB"

  tags = {
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "api-elb.k8s.flocloud.co"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group" "bastion-elb-k8s-flocloud-co" {
  name        = "bastion-elb.k8s.flocloud.co"
  vpc_id      = "vpc-06cc0d1f84a509986"
  description = "Security group for bastion ELB"

  tags = {
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "bastion-elb.k8s.flocloud.co"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group" "bastion-k8s-flocloud-co" {
  name        = "bastion.k8s.flocloud.co"
  vpc_id      = "vpc-06cc0d1f84a509986"
  description = "Security group for bastion"

  tags = {
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "bastion.k8s.flocloud.co"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group" "masters-k8s-flocloud-co" {
  name        = "masters.k8s.flocloud.co"
  vpc_id      = "vpc-06cc0d1f84a509986"
  description = "Security group for masters"

  tags = {
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "masters.k8s.flocloud.co"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group" "nodes-k8s-flocloud-co" {
  name        = "nodes.k8s.flocloud.co"
  vpc_id      = "vpc-06cc0d1f84a509986"
  description = "Security group for nodes"

  tags = {
    KubernetesCluster                       = "k8s.flocloud.co"
    Name                                    = "nodes.k8s.flocloud.co"
    "kubernetes.io/cluster/k8s.flocloud.co" = "owned"
  }
}

resource "aws_security_group_rule" "all-master-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.masters-k8s-flocloud-co.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-master-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.masters-k8s-flocloud-co.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "all-node-to-node" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

resource "aws_security_group_rule" "api-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.api-elb-k8s-flocloud-co.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-k8s-flocloud-co.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-elb-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.bastion-elb-k8s-flocloud-co.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion-to-master-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.bastion-k8s-flocloud-co.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion-to-node-ssh" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.bastion-k8s-flocloud-co.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "https-api-elb-31-145-22-154--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-k8s-flocloud-co.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["31.145.22.154/32"]
}

resource "aws_security_group_rule" "https-elb-to-master" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.api-elb-k8s-flocloud-co.id}"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "icmp-pmtu-api-elb-31-145-22-154--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.api-elb-k8s-flocloud-co.id}"
  from_port         = 3
  to_port           = 4
  protocol          = "icmp"
  cidr_blocks       = ["31.145.22.154/32"]
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.masters-k8s-flocloud-co.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-egress" {
  type              = "egress"
  security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "node-to-master-protocol-ipip" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "4"
}

resource "aws_security_group_rule" "node-to-master-tcp-1-2379" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 1
  to_port                  = 2379
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-2382-4001" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 2382
  to_port                  = 4001
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-tcp-4003-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 4003
  to_port                  = 65535
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "node-to-master-udp-1-65535" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.masters-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.nodes-k8s-flocloud-co.id}"
  from_port                = 1
  to_port                  = 65535
  protocol                 = "udp"
}

resource "aws_security_group_rule" "ssh-elb-to-bastion" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.bastion-k8s-flocloud-co.id}"
  source_security_group_id = "${aws_security_group.bastion-elb-k8s-flocloud-co.id}"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "ssh-external-to-bastion-elb-31-145-22-154--32" {
  type              = "ingress"
  security_group_id = "${aws_security_group.bastion-elb-k8s-flocloud-co.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["31.145.22.154/32"]
}

terraform = {
  required_version = ">= 0.9.3"
}
