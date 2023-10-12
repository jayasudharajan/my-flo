provider "postgresql" {
  host            = "${var.postgresql_host}"
  port            = "${var.postgresql_port}"
  database        = "${var.postgresql_database}"
  username        = "${var.postgresql_user}"
  password        = "${var.postgresql_password}"
  sslmode         = "require"
  connect_timeout = 15
  superuser = false
}