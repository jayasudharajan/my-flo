terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-098786959887"
    profile = "flo-dev"
    key    = "us-west-2/k8s/dev/api-lb.tfstate"
  }
}
provider "aws" {
  profile = "flo-dev"
  region = "us-west-2"
}
