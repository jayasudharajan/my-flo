variable "lte_public_subnet_a" {
  type = string
  default = "10.230.10.0/23"
}
variable "lte_public_subnet_b" {
  type = string
  default = "10.230.12.0/23"
}
variable "lte_public_subnet_c" {
  type = string
  default = "10.230.14.0/23"
}

variable "lte_private_subnet_a" {
  type = string
  default = "10.230.20.0/23"
}
variable "lte_private_subnet_b" {
  type = string
  default = "10.230.22.0/23"
}
variable "lte_private_subnet_c" {
  type = string
  default = "10.230.24.0/23"
}

variable "lte_dns_server_ip_1" {
  type = string
  default = "10.230.10.62"
}
variable "lte_dns_server_ip_2" {
  type = string
  default = "10.230.12.175"
}

variable "lte_vpc_key_pair" {
  type = string
  default = "mgmt-vpc"
}

variable "lte_ntp_server_count" {
  type    = number
  default = 3
}
