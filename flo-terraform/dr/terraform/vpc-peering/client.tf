module "vpc_peering" {
  source = "git::https://github.com/kloia/terraform-modules.git//peering?ref=v0.0.13"

  requester_vpc_id = "${var.aws["vpcId"]}"
  accepter_vpc_id  = "${var.vpc_peering["accepter_vpc_id"]}"
  accepter_profile = "${var.global["profile"]}"
  requester_profile = "${var.global["profile"]}"
  accepter_region = "${var.aws["region"]}"
  requester_region = "${var.aws["region"]}"
}
