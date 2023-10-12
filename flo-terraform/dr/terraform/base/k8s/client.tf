data "aws_acm_certificate" "elb" { ## that using old cert for enable at elb
  domain   = "*.flocloud.${var.domain}"
  statuses = ["ISSUED"]
}


module "kops-bucket-s3" {
  source = "git::https://github.com/kloia/terraform-modules.git//s3?ref=v0.0.1"
  name = "${var.kops_bucket_name}"
  tag_env = "${var.tag_env}"
  tag_name = "${var.tag_name}"

}

output "kops_s3_bucket" {
  value = "${module.kops-bucket-s3.bucket_domain_name}"
}


module "vpc" {
  source = "git::ssh://git@gitlab.com/flotechnologies/devops/terraform-modules.git//vpc?ref=vpc-tf11"
  private_subnet_count = 3
  public_subnet_count = 3
  vpc_cidr = "${var.cidr_block}"
  tag_organisation = "${var.tag_organisation}"
  tag_deployment ="${var.tag_deployment}"
  tag_deployment_code = "${var.tag_deployment_code}"
  tag_kubernetes_cluster = "${var.tag_kubernetes_cluster}"
  tag_project = "${var.tag_project}"
}


output "inner_acm_id" {
  value = "${data.aws_acm_certificate.elb.arn}"
}

output "inner_igw_id" {
  value = "${module.vpc.igw_id}"
}

output "inner_nat_gateway_id" {
  value = "${module.vpc.nat_gateway_id}"
}

output "inner_vpc_azs" {
  value = "${module.vpc.azs}"
}

output "inner_vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "inner_private_route_table_ids" {
  value = "${module.vpc.private_route_table_ids}"
}

output "inner_private_subnet_cidrs" {
  value = "${module.vpc.private_subnet_cidrs}"
}

output "inner_public_subnet_cidrs" {
    value = "${module.vpc.public_subnet_cidrs}"
}

output "inner_vpc_cidr_block" {
  value = "${module.vpc.vpc_cidr}"
}

output "inner_private_subnet_ids" {
  value = "${module.vpc.private_subnets_ids}"
}

output "inner_public_subnet_ids" {
    value = "${module.vpc.public_subnets_ids}"
}

module "route53-k8s" {
  source = "git::https://github.com/kloia/terraform-modules.git//route53?ref=v0.0.1"
  domain = "${var.route53_domain}"

}

output "k8szoneid" {
    value = "${module.route53-k8s.zone_id}"

}

output "k8sclustername" {
  value = "${module.route53-k8s.cluster_name}"
}


output "k8sns" {
    value = "${module.route53-k8s.ns_output}"

}

output "kops_cluster_name" {
  value = "${var.tag_env}-${var.tag_project}"
}
