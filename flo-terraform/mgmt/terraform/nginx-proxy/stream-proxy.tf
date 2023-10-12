resource "aws_lb" "proxy_lb_api_bulk" {
  internal            = true
  ip_address_type     = "ipv4"
  load_balancer_type  = "network"
  subnets             = data.aws_subnet_ids.public_subnet_ids.ids

  enable_deletion_protection = false

  tags = {
    AutoScalingGroupName  = var.nginx_proxy_asg_name
    Environment           = "production"
    TfName                = "proxy_lb_api_bulk"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "proxy_lb_s3_mender" {
  internal            = true
  ip_address_type     = "ipv4"
  load_balancer_type  = "network"
  subnets             = data.aws_subnet_ids.public_subnet_ids.ids

  enable_deletion_protection = false

  tags = {
    AutoScalingGroupName  = var.nginx_proxy_asg_name
    Environment           = "production"
    TfName                = "proxy_lb_s3_mender"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_api_bulk_8443" {
  name        = "${var.name}-api-bulk-https"
  port        = 8443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "proxy_target_s3_mender_9443" {
  name        = "${var.name}-s3-mender-https"
  port        = 9443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_api_bulk_443" {
  load_balancer_arn   = aws_lb.proxy_lb_api_bulk.arn
  port                = 443
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_api_bulk_8443.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "proxy_listener_s3_mender_443" {
  load_balancer_arn   = aws_lb.proxy_lb_s3_mender.arn
  port                = 443
  protocol            = "TCP"

  default_action {
    type      = "forward"
    target_group_arn  = aws_lb_target_group.proxy_target_s3_mender_9443.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_api_bulk_443" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_api_bulk_8443.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "proxy_asg_attachment_s3_mender_443" {
  autoscaling_group_name      = aws_autoscaling_group.proxy_asg.id
  alb_target_group_arn        = aws_lb_target_group.proxy_target_s3_mender_9443.arn

  lifecycle {
    create_before_destroy = true
  }
}
