resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"

  tags = {
    Name = "vault-kms-unseal-key"
    Deployment = "dev"
    Project = "k8s"
  }
}
