terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-617288038711"
    profile = "flo-prod"
    key    = "us-west-2/eks/cluster.tfstate"
  }
  required_version = ">= 0.12"
}
provider "aws" {
  profile = "flo-prod"
  region = var.region
}
