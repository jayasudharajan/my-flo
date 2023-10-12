##
# Extra Flo-specific IAM policy
##


data "aws_iam_policy_document" "flo-extra-policy-document" {
  statement {
    sid = "1"
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]

    resources = [
      "arn:aws:route53:::change/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:*",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:*"
    ]
    resources = [
      "arn:aws:sns:${var.region}:${var.account_id}:app/GCM/flo-notifications-prod",
      "arn:aws:sns:${var.region}:${var.account_id}:app/APNS/flo-prod"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:*"
    ]
  }


  statement {
    sid = "TimescaleBackupList"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetBucketLocation"

    ]

    resources = [
      "arn:aws:s3:::${var.general-backup-s3-bucket}",
      "arn:aws:s3:::${var.tf-state-s3-bucket}",
    ]
  }

  statement {
    sid = "AllowEventBridgeAccess"
    effect = "Allow"
    actions = [
      "events:DescribeEventBus",
      "events:PutEvents"
    ]

    resources = [
      "arn:aws:events:us-west-2:617288038711:event-bus/*"
    ]
  }

  statement {
    sid = "TimescaleBackupCRUD"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*"

    ]

    resources = [
      "arn:aws:s3:::${var.general-backup-s3-bucket}/tsdb/*",
      "arn:aws:s3:::${var.tf-state-s3-bucket}/${var.region}/timescale-backup/*",
    ]
  }


  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:Delete*",

    ]

    resources = [
      "arn:aws:s3:::${var.config-s3-bucket}",
      "arn:aws:s3:::${var.config-s3-bucket}/*",
      "arn:aws:s3:::${var.devices-s3-bucket}",
      "arn:aws:s3:::${var.devices-s3-bucket}/*",
      "arn:aws:s3:::${var.cert-authority-bucket}",
      "arn:aws:s3:::${var.cert-authority-bucket}/*",
      "arn:aws:s3:::${var.flodetect-archive-s3-bucket}",
      "arn:aws:s3:::${var.flodetect-archive-s3-bucket}/*",
      "arn:aws:s3:::${var.batch-hf-append-s3-bucket}",
      "arn:aws:s3:::${var.batch-hf-append-s3-bucket}/*",
      "arn:aws:s3:::${var.config-s3-bucket}/docker/*",
      "arn:aws:s3:::${var.config-s3-bucket}/filebeat/*",
      "arn:aws:s3:::${var.config-s3-bucket}/hivemq4/prod/*",
      "arn:aws:s3:::${var.batch-append-s3-bucket}",
      "arn:aws:s3:::${var.batch-append-s3-bucket}/*",
      "arn:aws:s3:::${var.bulk-device-telemetry-s3-bucket}",
      "arn:aws:s3:::${var.bulk-device-telemetry-s3-bucket}/*",
      "arn:aws:s3:::${var.flosense-models-s3-bucket}",
      "arn:aws:s3:::${var.flosense-models-s3-bucket}/*",
      "arn:aws:s3:::${var.incident-archive-s3-bucket}",
      "arn:aws:s3:::${var.incident-archive-s3-bucket}/*",
      "arn:aws:s3:::${var.device-healthtests-bucket}",
      "arn:aws:s3:::${var.device-healthtests-bucket}/*",
      "arn:aws:s3:::${var.puck-archive-bucket}",
      "arn:aws:s3:::${var.puck-archive-bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",

    ]

    resources = [
      "arn:aws:s3:::${var.bulk-device-telemetry-s3-bucket}/*",
      "arn:aws:s3:::${var.config-s3-bucket}/docker/*",
      "arn:aws:s3:::${var.config-s3-bucket}/filebeat/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-api/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-api/mqtt-client-certs/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-ca/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-ca/prod/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-directive-response/prod/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-directive-router/prod/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-directive-router/mqtt-client-certs/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-email-reports-generator/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-encryption/dynamodb/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-encryption/kafka/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-encryption/prod/kafka/*",
      "arn:aws:s3:::${var.config-s3-bucket}/flo-apps/flo-kafka-tls/*",
      "arn:aws:s3:::${var.devices-s3-bucket}/devices/device-*/qrcode/*.svg",
      "arn:aws:s3:::${var.devices-s3-bucket}/devices/device-*/qrcode/*.png",
      "arn:aws:s3:::${var.letters-s3-bucket}/*.pdf"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:${var.account_id}:table/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/dev/apps/flo-email-reports-generator/docker-auth",
      "arn:aws:kms:${var.region}:${var.account_id}:alias/aws/secretsmanager"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey"
    ]

    resources = [
      "arn:aws:kms:${var.region}:${var.account_id}:key/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:us-east-1:877653870079:amazon-key-partner-events",
      "arn:aws:sns:us-west-2:070412871651:amazon-key-partner-events-test"
    ]
  }

  statement {
    sid = "LogstashToS3"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
      "s3:Delete*",

    ]

    resources = [
      "arn:aws:s3:::${var.app-logs-s3-bucket}",
      "arn:aws:s3:::${var.app-logs-s3-bucket}/*"
    ]
  }

  statement {
    sid = "CertManager"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]

    resources = [
      "arn:aws:route53:::hostedzone/Z3UXYMQBRBDL6J",
      "arn:aws:route53:::hostedzone/Z3IRHXAP4XLUUY",
      "arn:aws:route53:::hostedzone/Z2083Y9US8BS1"
    ]
  }

  statement {
    sid = "CertManagerMgmtAccountAccess"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::${var.mgmt_account_id}:role/${var.mgmt_account_assumed_role}"
    ]
  }
}

resource "aws_iam_policy" "flo-extra-policy" {
  name = "flo-extra-policy-eks-nodes"
  policy = data.aws_iam_policy_document.flo-extra-policy-document.json
}

resource "aws_iam_role_policy_attachment" "node-extra-flo-Policy" {
  policy_arn = aws_iam_policy.flo-extra-policy.arn
  role = aws_iam_role.node-role.name
}
