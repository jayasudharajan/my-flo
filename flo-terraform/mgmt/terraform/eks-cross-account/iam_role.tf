resource "aws_iam_role" "eks-node-role" {
  assume_role_policy = <<POLICY
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Condition": {},
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::617288038711:root"
      }
    }
  ],
  "Version": "2012-10-17"
}
POLICY

  managed_policy_arns  = ["arn:aws:iam::260332691473:policy/flo-extra-policy-eks-nodes"]
  max_session_duration = "3600"
  name                 = "eks-node-role"
  path                 = "/"
}
