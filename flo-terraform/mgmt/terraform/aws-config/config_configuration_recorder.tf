resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "default" {
  name = "default"

  recording_group {
    all_supported                 = "true"
    include_global_resource_types = "true"
  }

  role_arn = aws_iam_service_linked_role.config.arn
}
