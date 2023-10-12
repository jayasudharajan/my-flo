variable "name" {
  type          = string
  description   = "Stack base-name"
  default       = "lte-proxy"
}

variable "region" {
  type          = string
  description   = "AWS Region"
  default       = "us-west-2"
}

variable "ami" {
  type        = string
  description = "The EC2 image ID to launch."
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type to launch."
  default     = "t4a.small"
}

variable "nginx_proxy_asg_name" {
  type          = string
  description   = "Stack base-name"
  default       = "lte-proxy-asg"
}

variable "vpc_id" {
  type          = string
  description   = "VPC ID"
}

variable "private_subnet_name_tag" {
  type          = string
  description   = "`Name` tag value for private subnet list"
  default       = "Private Subnet"
}

variable "public_subnet_name_tag" {
  type          = string
  description   = "`Name` tag value for public subnet list"
  default       = "Public Subnet"
}

variable "nginx_proxy_asg_max_size" {
  type          = number
  description   = "Max scaling group size"
  default       = 1
}

variable "nginx_proxy_asg_min_size" {
  type          = number
  description   = "Min scaling group size"
  default       = 1
}

variable "ssh_key_name" {
  type          = string
  description   = "SSH Key Name"
}
