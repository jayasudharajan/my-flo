terraform {
  backend "s3" {
    region = "us-east-2"
    bucket = "k8s-dr-terraform-state"
    key    = "us-east-2/dr/dr/natgw-elb-sec.tfstate"
    profile = "flo-dev"
  }
}
