terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-nexus-mgmt"
    profile = "flo-mgmt"
    key    = "us-west-2/backup.tfstate"
  }
}
provider "aws" {
  profile = "flo-mgmt"
  region = "us-west-2"
}
