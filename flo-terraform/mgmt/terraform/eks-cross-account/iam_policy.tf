resource "aws_iam_policy" "flo-extra-policy-eks-nodes" {
  name = "flo-extra-policy-eks-nodes"
  path = "/"

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "route53:GetChange",
      "Effect": "Allow",
      "Resource": "arn:aws:route53:::change/*",
      "Sid": "R53GetChangeSets"
    },
    {
      "Action": "route53:ListHostedZonesByName",
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "R53ListHostedZones"
    },
    {
      "Action": [
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:route53:::hostedzone/Z3IRHXAP4XLUUY",
      "Sid": "CertManager"
    }
  ],
  "Version": "2012-10-17"
}
POLICY
}
