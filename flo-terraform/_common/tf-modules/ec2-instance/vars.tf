variable "name" {
  type = string
}

variable "type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_groups" {
  type = list(string)
  default = null
}

variable "ebs_optimized" {
  type        = bool
  default     = true
}

variable "root_device_details" {
  type        = list(map(string))
  default     = []
}

variable "key_name" {
  type        = string
  default     = ""
}

variable "ebs_devices" {
  type        = list(map(string))
  default     = []
}

variable "iam_instance_profile" {
  type        = string
  default     = ""
}

variable "tags" {
  type        = map(string)
  default     = {}
}