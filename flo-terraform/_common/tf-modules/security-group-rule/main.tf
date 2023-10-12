variable "type" {
  type = string
  default = "ingress"
}

variable "from_port" {
  type = number
  default = 0
}

variable "to_port" {
  type = number
}

variable "protocol" {
  type = string
  default = "tcp"
}

variable "source_cidrs" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "security_group_id" {
  type = string
}

resource "aws_security_group_rule" "rule" {
  type              = var.type
  from_port         = var.from_port
  to_port           = var.to_port
  protocol          = var.protocol
  cidr_blocks = var.source_cidrs
  security_group_id = var.security_group_id
}
