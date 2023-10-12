variable "region" {
  type = string
  default = "us-west-2"
}

variable "account_id" {
  type = string
  default = "098786959887"
}

variable "primary_eks_node_group_type" {
  type = string
  default = "t3a.xlarge"
}

variable "cluster_name" {
  type = string
  default = "eks-flocloud-co"
}

variable "public_subnet_id_a" {
  type = string
  default = "subnet-04dc2cad14c7d8abc"
}

variable "public_subnet_id_b" {
  type = string
  default = "subnet-a8c538de"
}

variable "public_subnet_id_c" {
  type = string
  default = "subnet-58eb333c"
}

variable "private_subnet_id_a" {
  type = string
  default = "subnet-a9c538df"
}

variable "private_subnet_id_b" {
  type = string
  default = "subnet-5feb333b"
}

variable "private_subnet_id_c" {
  type = string
  default = "subnet-07ab52e3de6d0ff73"
}

variable "config-s3-bucket" {
  type = string
  default = "flocloud-config"
}

variable "bulk-device-telemetry-s3-bucket" {
  type = string
  default = "flocloud-bulk-device-telemetry"
}

variable "devices-s3-bucket" {
  type = string
  default = "flocloud-devices"
}

variable "batch-hf-append-s3-bucket" {
  type = string
  default = "flocloud-batch-hf-append"
}

variable "batch-append-s3-bucket" {
  type = string
  default = "flocloud-batch-append"
}

variable "flosense-models-s3-bucket" {
  type = string
  default = "flocloud-flosense-models"
}

variable "general-backup-s3-bucket" {
  type = string
  default = "flocloud-backup"
}

variable "incident-archive-s3-bucket" {
  type = string
  default = "flocloud-incident-archive"
}

variable "letters-s3-bucket" {
  type = string
  default = "flocloud-letters"
}

variable "app-logs-s3-bucket" {
  type = string
  default = "flocloud-logs"
}

variable "puck-archive-bucket" {
  type = string
  default = "flocloud-puck-archive"
}

variable "tf-state-s3-bucket" {
  type = string
  default = "flo-terraform-state-098786959887"
}
