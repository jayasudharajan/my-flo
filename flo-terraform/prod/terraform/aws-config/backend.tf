terraform {
  backend "s3" {
    region = "us-west-2"
    profile = "flo-prod"
    bucket = "flo-terraform-state-617288038711"
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
  profile = "flo-prod"
  region  = "us-west-2"
}
