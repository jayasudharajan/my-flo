variable "group_name" {
  type = string
}

variable "vpc_id" {
  type = string
}



resource "aws_security_group" "standalone_security_group" {
  name        = var.group_name
  vpc_id      = var.vpc_id

  tags = {
    Name = var.group_name
  }
}
