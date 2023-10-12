variable "name" {
  type = string
}

variable "certificate_id" {
  type = string
}

variable "instances" {
  type = list(string)
  default = []
}

variable "instance_port_number" {
  type = number
}

variable "health_check_healthy_threshold" {
  type = number
  default = 2
}

variable "health_check_unhealthy_threshold" {
  type = number
  default = 2
}

variable "health_check_timeout" {
  type = number
  default = 10
}

variable "health_check_target" {
  type = string
  default = "HTTP:80/"
}

variable "health_check_interval" {
  type = number
  default = 30
}

variable "cross_zone_load_balancing" {
  type = bool
  default = true
}

variable "idle_timeout" {
  type = number
  default = 400
}

variable "connection_draining" {
  type = bool
  default = true
}

variable "connection_draining_timeout" {
  type = number
  default = 400
}

variable "availability_zones" {
  type = list(string)
  //default = ["us-west-2a", "us-west-2b"]
  default = null
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
  default = null
}

resource "aws_elb" "a" {
  name = "${var.name}-elb"
  availability_zones = var.availability_zones

  subnets = var.subnets

  listener {
    instance_port = var.instance_port_number
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = var.certificate_id
  }
  instances                   = var.instances
  security_groups             = var.security_groups
  cross_zone_load_balancing   = var.cross_zone_load_balancing
  idle_timeout                = var.idle_timeout
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout



  tags = {
    Name = "${var.name}-elb"
  }
  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    target              = var.health_check_target
    interval            = var.health_check_interval
  }
}