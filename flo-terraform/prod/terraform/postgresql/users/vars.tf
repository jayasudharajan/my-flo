variable "postgresql_host" {
  default = "localhost"
}

variable "postgresql_port" {
  default = 5432
}

variable "postgresql_user" {
  default = "postgres"
}

variable "postgresql_password" {
  default = ""
}

variable "postgresql_database" {
  default = ""
}

variable "developers" {
  description = "Create Database Users with these names"
  type = "map"
  default = {artem = "passw0rd"}
}