terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-mgmt"
    profile = "flo-mgmt"
    key    = "us-west-2/lte-vpc/lte-vpc.tfstate"
  }
}
provider "aws" {
  profile = "flo-mgmt"
  region = "us-west-2"
}
