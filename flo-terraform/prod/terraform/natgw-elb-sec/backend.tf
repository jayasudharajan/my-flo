terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flosecurecloud-terraform-state-617288038711"
    key    = "us-west-2/k8s-prod/prod/natgw-elb-sec.tfstate"
    profile = "flo-prod"
  }
}
