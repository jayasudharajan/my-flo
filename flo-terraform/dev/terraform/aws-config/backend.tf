terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-098786959887"
    profile = "flo-dev"
    key    = "us-west-2/aws-config/config.tfstate"
  }
  required_providers {
    aws = {
      version = "~> 3.32.0"
    }
  }
  required_version = ">= 0.12"
}
provider "aws" {
  profile = "flo-dev"
  region = "us-west-2"
}
