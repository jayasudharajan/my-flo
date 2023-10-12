data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.eks-cluster.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks-cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks-cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.node-role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML
    mapUsers = <<YAML
- userarn: arn:aws:iam::617288038711:user/sebastien.dejean
  username: sebastien.dejean
  groups:
    - system:masters
YAML
  }
}