variable "postgresql_host" {
  default = "prod-rds.cutnsvmodttf.us-west-2.rds.amazonaws.com"
}

variable "postgresql_port" {
  default = 5432
}

variable "postgresql_user" {
  default = "master"
}

variable "postgresql_password" {
  default = ""
}

variable "postgresql_database" {
  default = "postgres"
}

variable "developers" {
  description = "Create Database Users with these names"
  type = "map"
  default = {artem = "passw0rd"}
}