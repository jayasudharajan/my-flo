output "region" {
  value = "${data.aws_region.current.name}"
}

output "kubernetes_cluster_name" {
  value = "${local.cluster_name}"
}

output "kops_s3_bucket" {
  value = "${module.kops.kops_s3_bucket}"
}

output "availability_zones" {
  value = "${module.kops.inner_vpc_azs}"
}

output "kops_vpc_id" {
  value = "${module.kops.inner_vpc_id}"
}

output "kops_vpc_private_rt_ids" {
  value = "${module.kops.inner_private_route_table_ids}"
}

output "kops_vpc_private_subnet_cidrs" {
  value = "${module.kops.inner_private_subnet_cidrs}"
}

output "kops_vpc_public_subnet_cidrs" {
  value = "${module.kops.inner_public_subnet_cidrs}"
}


output "kops_vpc_cidr_block" {
  value = "${module.kops.inner_vpc_cidr_block}"
}

output "public_subnet_ids" {
  value = "${module.kops.inner_public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.kops.inner_private_subnet_ids}"
}

output "kops_zone_id" {
  value = "${module.kops.k8szoneid}"
}

output "kops_name_servers" {
  value = "${module.kops.k8sns}"
}

output "kops_nat_gateway_id" {
  value = ["${module.kops.inner_nat_gateway_id}"]
}

output "kops_igw" {
  value = "${module.kops.inner_igw_id}"
}

output "kops_acm_id" {
  value = "${module.kops.inner_acm_id}"
}
