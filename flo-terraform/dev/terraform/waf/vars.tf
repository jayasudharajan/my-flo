variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
  default     = "flo-pubgw-rate-limit"
}

variable "profile" {
  type = string
  default = "flo-dev"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "requests_per_ip_limit" {
  type = number
  default = 100
}