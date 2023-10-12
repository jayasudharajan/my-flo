terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-mgmt"
    profile = "flo-mgmt"
    key    = "us-west-2/lte-tunnel-proxy/lte-tunnel-proxy.tfstate"
  }
}
provider "aws" {
  profile = "flo-mgmt"
  region = "us-west-2"
  version = "~> 3.21"
}
