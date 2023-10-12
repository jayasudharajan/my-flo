terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-098786959887"
    profile = "flo-dev"
    key    = "us-west-2/k8s/dev/waf.tfstate"
  }
}
provider "aws" {
  profile = var.profile
  region = "us-west-2"
}
