resource "aws_config_config_rule" "access-keys-rotated" {
  depends_on                  = [aws_config_configuration_recorder.default]
  description                 = "Checks whether the active access keys are rotated within the number of days specified in maxAccessKeyAge. The rule is non-compliant if the access keys have not been rotated for more than maxAccessKeyAge number of days."
  input_parameters            = "{\"maxAccessKeyAge\":\"90\"}"
  maximum_execution_frequency = "TwentyFour_Hours"
  name                        = "access-keys-rotated"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }
}

resource "aws_config_config_rule" "cloud-trail-encryption-enabled" {
  depends_on                  = [aws_config_configuration_recorder.default]
  description                 = "Checks whether AWS CloudTrail is configured to use the server side encryption (SSE) AWS Key Management Service (AWS KMS) customer master key (CMK) encryption. The rule is compliant if the KmsKeyId is defined."
  input_parameters            = "{}"
  maximum_execution_frequency = "TwentyFour_Hours"
  name                        = "cloud-trail-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
}

resource "aws_config_config_rule" "dynamodb-table-encrypted-kms" {
  depends_on       = [aws_config_configuration_recorder.default]
  description      = "Checks whether Amazon DynamoDB table is encrypted with AWS Key Management Service (KMS). The rule is NON_COMPLIANT if Amazon DynamoDB table is not encrypted with AWS KMS."
  input_parameters = "{}"
  name             = "dynamodb-table-encrypted-kms"

  scope {
    compliance_resource_types = ["AWS::DynamoDB::Table"]
  }

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }
}

resource "aws_config_config_rule" "iam-user-unused-credentials-check" {
  depends_on       = [aws_config_configuration_recorder.default]
  description      = "Checks if your AWS Identity and Access Management (IAM) users have passwords or active access keys that have not been used within the specified number of days you provided."
  input_parameters = "{\"maxCredentialUsageAge\":\"90\"}"
  maximum_execution_frequency = "TwentyFour_Hours"
  name             = "iam-user-unused-credentials-check"

  # scope {
  #   compliance_resource_types = ["AWS::IAM::User"]
  # }

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }
}

resource "aws_config_config_rule" "s3-bucket-level-public-access-prohibited" {
  depends_on       = [aws_config_configuration_recorder.default]
  description      = "Checks if Amazon Simple Storage Service (Amazon S3) buckets are publicly accessible. This rule is NON_COMPLIANT if an Amazon S3 bucket is not listed in the excludedPublicBuckets parameter and bucket level settings are public."
  input_parameters = "{}"
  name             = "s3-bucket-level-public-access-prohibited"

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3-default-encryption-kms" {
  depends_on       = [aws_config_configuration_recorder.default]
  description      = "Checks whether the Amazon S3 buckets are encrypted with AWS Key Management Service(AWS KMS). The rule is NON_COMPLIANT if the Amazon S3 bucket is not encrypted with AWS KMS key."
  input_parameters = "{}"
  name             = "s3-default-encryption-kms"

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  source {
    owner             = "AWS"
    source_identifier = "S3_DEFAULT_ENCRYPTION_KMS"
  }
}
