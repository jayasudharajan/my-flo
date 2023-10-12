variable "ec2_instance_type" {
  type = string
  default = "a1.large" // c5.large for production ?
}

variable "ec2_ami_id" {
  type = string
  default = "ami-0fc025e3171c5a1bf" # ubuntu 18.04 us-west-2 arm
}

variable "vpc_id" {
  type = string
  default = "vpc-046b4c62" # mgmt-vpc
}

variable "subnet_id" {
  type = string
  default = "subnet-0d4a7262519dd071c" # dev-vpc-PrivateC
}

variable "elb_subnet_list" {
  type = list(string)
  default = ["subnet-0af0dabcee10c278a"]
}

variable "nexus-tls-certificate" {
  type = string
  default = "arn:aws:acm:us-west-2:260332691473:certificate/1e1c0c6c-928b-42fd-a911-c2607ef7c0d0" # *.flotech.co
}

variable "key_name" {
  type = string
  default = "mgmt-vpc"
}