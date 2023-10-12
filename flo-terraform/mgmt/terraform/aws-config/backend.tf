terraform {
  backend "s3" {
    region = "us-west-2"
    profile = "flo-mgmt"
    bucket = "flo-terraform-state-mgmt"
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
  profile = "flo-mgmt"
  region  = "us-west-2"
}
