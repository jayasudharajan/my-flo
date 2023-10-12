data "tls_certificate" "eks_certificate" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}

resource "aws_eks_cluster" "eks-cluster" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks-cluster-role.arn
  vpc_config {
    subnet_ids = [var.public_subnet_id_a, var.public_subnet_id_b, var.public_subnet_id_c]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-policy-attachment,
    aws_iam_role_policy_attachment.eks-service-policy-attachment,
  ]

}

resource "random_pet" "node-group" {
  keepers = {
    # Generate a new pet name each time we switch to a new instance type
    instance_type = var.primary_eks_node_group_type
  }
}

resource "aws_eks_node_group" "primary-node-group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "primary-group-${random_pet.node-group.id}"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = [var.private_subnet_id_a, var.private_subnet_id_b, var.private_subnet_id_c]
  instance_types = [
    # Read the instnce type "through" the random_pet resource to ensure that
    # both will change together.
    random_pet.node-group.keepers.instance_type
  ]
  disk_size = 100
  version = "1.18"
  scaling_config {
    desired_size = 9
    max_size     = 11
    min_size     = 6
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks-cluster.identity.0.oidc.0.issuer
}
