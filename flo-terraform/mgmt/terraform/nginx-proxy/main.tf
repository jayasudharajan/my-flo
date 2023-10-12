resource "aws_security_group" "proxy_instance_sg" {
  name_prefix = "proxy_instance_sg"
  description = "Allow inbound HTTP(s), ICMP, HTTP and SSH traffic"
  vpc_id = var.vpc_id
  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 943
    protocol = "tcp"
    to_port = 943
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 1194
    protocol = "udp"
    to_port = 1194
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 8000
    protocol = "tcp"
    to_port = 8000
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 8001
    protocol = "tcp"
    to_port = 8001
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 8443
    protocol = "tcp"
    to_port = 8443
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 8883
    protocol = "tcp"
    to_port = 8883
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 8884
    protocol = "tcp"
    to_port = 8884
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port = 9443
    protocol = "tcp"
    to_port = 9443
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    AutoScalingGroupName  = var.nginx_proxy_asg_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "proxy_asg_launch_template" {
  name_prefix   = var.nginx_proxy_asg_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.proxy_instance_profile.arn
  }

  image_id      = local.ami
  instance_type = "a1.medium"
  key_name      = var.ssh_key_name

  user_data = filebase64("${path.module}/templates/userdata.sh")

  vpc_security_group_ids = [
    aws_security_group.proxy_instance_sg.id
  ]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                  = var.name
      AutoScalingGroupName  = var.nginx_proxy_asg_name
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name                  = var.name
      AutoScalingGroupName  = var.nginx_proxy_asg_name
    }
  }
}

resource "aws_autoscaling_group" "proxy_asg" {
  name            =  var.nginx_proxy_asg_name
  max_size        =  var.nginx_proxy_asg_max_size
  min_size        =  var.nginx_proxy_asg_min_size

  launch_template {
    id  = aws_launch_template.proxy_asg_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnet_ids.private_subnet_ids.ids

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "AutoScalingGroupName"
    value               = "var.nginx_proxy_asg_name"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }
}

# Leave name blank here to give Terraform latitude and also because
# `name_prefix` is so short its effectively useless for LBs
resource "aws_lb" "proxy_load_balancer" {
  internal            = true
  ip_address_type     = "ipv4"
  load_balancer_type  = "network"
  subnets             = data.aws_subnet_ids.public_subnet_ids.ids

  enable_deletion_protection = false

  tags = {
    AutoScalingGroupName  = var.nginx_proxy_asg_name
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_http" {
  name        = "${var.name}-http"
  port        = 80
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_https" {
  name        = "${var.name}-https"
  port        = 443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_odt_943" {
  name        = "${var.name}-odt-943"
  port        = 943
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_odt_1194" {
  name        = "${var.name}-odt-1194"
  port        = 1194
  protocol    = "UDP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled   = true
    interval  = 30
    protocol  = "TCP"
    port      = 943
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_mqtt_8000" {
  name        = "${var.name}-mqtt-8000"
  port        = 8000
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_mqtt_8001" {
  name        = "${var.name}-mqtt-8001"
  port        = 8001
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_mqtt_8883" {
  name        = "${var.name}-mqtt-8883"
  port        = 8883
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_target_group" "proxy_target_mqtt_8884" {
  name        = "${var.name}-mqtt-8884"
  port        = 8884
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_http" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 80
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_http.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_https" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 443
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_https.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_odt_943" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 943
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_odt_943.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_odt_1194" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 1194
  protocol            = "UDP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_odt_1194.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_mqtt_8000" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 8000
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_mqtt_8000.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_mqtt_8001" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 8001
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_mqtt_8001.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_mqtt_8883" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 8883
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_mqtt_8883.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_mqtt_8884" {
  load_balancer_arn   = aws_lb.proxy_load_balancer.arn
  port                = 8884
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_mqtt_8884.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_http" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_http.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_https" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_https.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_mqtt_8000" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_mqtt_8000.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_mqtt_8001" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_mqtt_8001.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_mqtt_8883" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_mqtt_8883.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_mqtt_8884" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_mqtt_8884.arn

  lifecycle {
    create_before_destroy = true
  }
}
