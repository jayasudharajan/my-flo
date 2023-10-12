variable "region" {
  type = string
  default = "us-west-2"
}

variable "account_id" {
  type = string
  default = "617288038711"
}

variable "primary_eks_node_group_type" {
  type = string
  default = "c5.2xlarge"
}


variable "cluster_name" {
  type = string
  default = "eks-flosecurecloud-com"
}

variable "public_subnet_id_a" {
  type = string
  default = "subnet-0d0b5769"
}

variable "public_subnet_id_b" {
  type = string
  default = "subnet-8ff580f9"
}

variable "public_subnet_id_c" {
  type = string
  default = "subnet-091ddd5471c16c7e4"
}

variable "private_subnet_id_a" {
  type = string
  default = "subnet-0f0b576b"
}

variable "private_subnet_id_b" {
  type = string
  default = "subnet-8ef580f8"
}

variable "private_subnet_id_c" {
  type = string
  default = "subnet-0cd33a29fb482c522"
}

variable "config-s3-bucket" {
  type = string
  default = "flosecurecloud-config"
}

variable "bulk-device-telemetry-s3-bucket" {
  type = string
  default = "flosecurecloud-bulk-device-telemetry"
}

variable "devices-s3-bucket" {
  type = string
  default = "flosecurecloud-devices"
}

variable "batch-hf-append-s3-bucket" {
  type = string
  default = "flosecurecloud-telemetry-batch-hf-append"
}

variable "batch-append-s3-bucket" {
  type = string
  default = "flosecurecloud-telemetry-batch-append"
}

variable "flosense-models-s3-bucket" {
  type = string
  default = "flosecurecloud-flosense-models"
}

variable "general-backup-s3-bucket" {
  type = string
  default = "flosecurecloud-backup"
}

variable "flodetect-archive-s3-bucket" {
  type = string
  default = "flosecurecloud-flodetect-archive"
}

variable "incident-archive-s3-bucket" {
  type = string
  default = "flosecurecloud-incident-archive"
}

variable "letters-s3-bucket" {
  type = string
  default = "flosecurecloud-letters"
}

variable "app-logs-s3-bucket" {
  type = string
  default = "flosecurecloud-logs"
}

variable "cert-authority-bucket" {
  type = string
  default = "flosecurecloud-vault"
}

variable "device-healthtests-bucket" {
  type = string
  default = "flosecurecloud-healthtests"
}

variable "mgmt_account_id" {
  type = string
  default = "260332691473"
}

variable "mgmt_account_assumed_role" {
  type = string
  default = "eks-node-role"
}

variable "puck-archive-bucket" {
  type = string
  default = "flosecurecloud-puck-archive"
}

variable "tf-state-s3-bucket" {
  type = string
  default = "flo-terraform-state-617288038711"
}

