
resource "aws_instance" "ai" {
  ami           = var.ami_id
  instance_type = var.type
  subnet_id = var.subnet_id
  iam_instance_profile = var.iam_instance_profile
  // should not be used! only for EC2 Classic instances
  //security_groups = var.security_groups
  vpc_security_group_ids = var.security_groups
  ebs_optimized = var.ebs_optimized

  key_name = var.key_name

  dynamic "root_block_device" {
    for_each = var.root_device_details
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_devices
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  tags = merge(
  {
    "Name" = var.name
  },
  var.tags,
  )

  volume_tags = merge(
  {
    "Name" = var.name
  },
  var.tags,
  )


}