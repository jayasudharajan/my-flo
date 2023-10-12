# TODO: IAM Role
resource "aws_iam_role" "proxy_instance_role" {
  name_prefix   = "${var.name}-instance"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AssumeRoleEC2"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "proxy_policy_ssm" {
  description   = "Provides instance access to SSM"
  name_prefix   = "${var.name}-policy-ssm"
  policy        = templatefile("${path.module}/templates/iam-policy-ssm.json", {})
}

resource "aws_iam_role_policy_attachment" "policy_ssm_attachment" {
  role      = aws_iam_role.proxy_instance_role.name
  policy_arn  = aws_iam_policy.proxy_policy_ssm.arn
}

resource "aws_iam_instance_profile" "proxy_instance_profile" {
  name_prefix   = "${var.name}-profile"
  role = aws_iam_role.proxy_instance_role.name
}
