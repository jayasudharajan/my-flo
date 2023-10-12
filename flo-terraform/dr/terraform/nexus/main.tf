module "nexus-elb-security-group" {
  source = "../../../_common/tf-modules/standalone-security-group"
  group_name = "nexus_elb_security_group"
  vpc_id = var.vpc_id
}

module "nexus-elb-security-group-egress-rule" {
  source = "../../../_common/tf-modules/security-group-rule"
  type = "egress"
  protocol = "-1"
  from_port = 0
  to_port = 0
  security_group_id = module.nexus-elb-security-group.id
}

module "nexus-elb-security-group-ingress-rule" {
  source = "../../../_common/tf-modules/security-group-rule"
  type = "ingress"
  protocol = "tcp"
  from_port = 443
  to_port = 443
  security_group_id = module.nexus-elb-security-group.id
}

module "nexus-instance-security-group" {
  source = "../../../_common/tf-modules/standalone-security-group"
  group_name = "nexus_instance_security_group"
  vpc_id = var.vpc_id
}

module "nexus-instance-security-group-ssh-rule" {
  source = "../../../_common/tf-modules/security-group-rule"
  to_port = 22
  security_group_id = module.nexus-instance-security-group.id
}

module "nexus-instance-security-group-web-rule" {
  source = "../../../_common/tf-modules/security-group-rule"
  to_port = 8081
  security_group_id = module.nexus-instance-security-group.id
}

module "nexus-instance-security-group-web-egress-rule" {
  source = "../../../_common/tf-modules/security-group-rule"
  type = "egress"
  protocol = "-1"
  from_port = 0
  to_port = 0
  security_group_id = module.nexus-instance-security-group.id
}



module "nexus_instance" {
  source = "../../../_common/tf-modules/ec2-instance"
  name = "dev-nexus-instance"
  type = var.ec2_instance_type
  ami_id = var.ec2_ami_id
  subnet_id = var.subnet_id
  security_groups = [module.nexus-instance-security-group.id]
  key_name = var.key_name
  root_device_details = [
    {
      volume_type = "gp2"
      volume_size = 20
    }
  ]

  ebs_devices = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp2"
      volume_size = 100
    }
  ]
}

module "nexus-elb" {
  source = "../../../_common/tf-modules/https-only-elb"
  name = "nexus-load-balancer"
  certificate_id = var.nexus-tls-certificate
  instance_port_number = 8081
  health_check_target = "HTTP:8081/COPYRIGHT.html"
  security_groups = ["${module.nexus-elb-security-group.id}"]
  instances = [module.nexus_instance.id]
  subnets = var.elb_subnet_list
}