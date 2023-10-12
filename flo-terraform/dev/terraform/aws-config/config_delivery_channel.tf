resource "aws_config_delivery_channel" "default" {
  depends_on     = [aws_config_configuration_recorder.default]
  name           = "default"
  s3_bucket_name = "config-bucket-098786959887"

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }
}
