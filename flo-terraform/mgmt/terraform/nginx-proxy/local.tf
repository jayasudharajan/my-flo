locals {
  ami_filters = {
    name                = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
    virtualization-type = ["hvm"]
  }

  ami                   = data.aws_ami.ubuntu.id
}
