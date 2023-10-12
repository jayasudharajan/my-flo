terraform {
  backend "s3" {
    region = "us-west-2"
    bucket = "flo-terraform-state-098786959887"
    key    = "us-west-2/k8s/dev/natgw-elb-sec.tfstate"
    profile = "flo"
  }
}
