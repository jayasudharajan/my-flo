module "kops" {
  source = "./k8s"
  use_route53_ns_record = 1
  route53_record_count = 0
  organisation = "${var.global["organisation"]}" 
  domain = "${var.global["domain"]}"

  route53_domain = "dr.flocloud.${var.global["domain"]}"
  kops_bucket_name = "${var.global["kopsBucket"]}"
  cidr_block = "${var.aws["cidrBlock"]}"
  route53_record_type = "NS"
  tag_organisation = "k8s-flo"
  tag_deployment = "k8s-flo"
  tag_deployment_code = "k8s-flo-deploy-code"
  tag_kubernetes_cluster = "${var.global["clusterName"]}"
  tag_project = "k8s-flo-project"
  tag_env = "k8s"
  tag_name = "k8s-state-store-flo"
}

data "aws_region" "current" {}

locals {
  cluster_name = "dr.flocloud.${var.global["domain"]}"
}
