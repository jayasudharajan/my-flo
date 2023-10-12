terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-098786959887"
    profile = "flo"
    key    = "us-west-2/k8s/dev/peering.tfstate"
  }
}
provider "aws" {
  profile = "flo"
  region = "us-west-2"
}
