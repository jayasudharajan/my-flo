terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flosecurecloud-terraform-state-617288038711"
    profile = "flo-prod"
    key    = "us-west-2/k8s-prod/prod/base.tfstate"
  }
}
provider "aws" {
  profile = "flo-prod"
  region = "us-west-2"
}
