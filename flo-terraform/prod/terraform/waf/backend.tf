terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-617288038711"
    profile = "flo-prod"
    key    = "us-west-2/k8s/prod/waf.tfstate"
  }
}
provider "aws" {
  profile = var.profile
  region = "us-west-2"
}
