resource "aws_config_configuration_recorder" "default" {
  name = "default"

  recording_group {
    all_supported                 = "true"
    include_global_resource_types = "false"
  }

  role_arn = "arn:aws:iam::098786959887:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}
