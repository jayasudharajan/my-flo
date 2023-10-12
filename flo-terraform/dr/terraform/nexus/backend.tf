terraform {
  backend "s3" {
    region = "us-east-2"
    bucket = "flo-terraform-state-nexus-mgmt"
    profile = "flo-mgmt"
    key    = "us-east-2/backup.tfstate"
  }
}
provider "aws" {
  profile = "flo-mgmt"
  region = "us-east-2"
}
