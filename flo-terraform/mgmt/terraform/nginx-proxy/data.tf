data "aws_ami" "ubuntu" {
  most_recent = true

  dynamic "filter" {
    for_each = local.ami_filters

    content {
      name   = filter.key
      values = filter.value
    }
  }

  owners = ["099720109477"] # Canonical
}

data "aws_route_tables" "private_rts" {
  vpc_id = var.vpc_id

  tags    = {
    SubnetRole = "Private"
  }
}

data "aws_subnet_ids" "private_subnet_ids" {
  vpc_id  = var.vpc_id

  tags    = {
    Name  = var.private_subnet_name_tag
  }
}

data "aws_subnet_ids" "public_subnet_ids" {
  vpc_id  = var.vpc_id

  tags    = {
    Name  = var.public_subnet_name_tag
  }
}
