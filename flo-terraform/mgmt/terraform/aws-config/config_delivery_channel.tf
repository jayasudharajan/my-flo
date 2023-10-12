resource "aws_s3_bucket" "config_delivery_bucket" {
  bucket  = "${var.bucket_basename}-${data.aws_caller_identity.current.account_id}"
  acl     = "private"
  policy  = templatefile("config_delivery_bucket_policy.json", { aws_account_id = data.aws_caller_identity.current.account_id, bucket = "${var.bucket_basename}-${data.aws_caller_identity.current.account_id}" })

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm =  "AES256"
      }
    }
  }

  tags = {
    Name      = "${var.bucket_basename}-${data.aws_caller_identity.current.account_id}"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "config_delivery_bucket" {
  bucket  = aws_s3_bucket.config_delivery_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

}

resource "aws_config_delivery_channel" "default" {
  depends_on     = [aws_config_configuration_recorder.default]
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_delivery_bucket.id

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }
}
