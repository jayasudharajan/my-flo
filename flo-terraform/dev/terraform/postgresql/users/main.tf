resource "postgresql_role" "developer_role" {
  name = "developer"
}


resource "postgresql_role" "developer_user" {
  name = "${element(keys(var.developers), count.index)}"
  password = "${lookup(var.developers, "${element(keys(var.developers), count.index)}")}"
  login = true
  count = "${length(var.developers)}"
  roles = ["developer"]
}

resource "postgresql_grant" "readonly_tables" {
  database    = "${var.postgresql_database}"
  role        = "${element(keys(var.developers), count.index)}"
  schema      = "public"
  object_type = "database"
  privileges  = ["ALL"]
  count = "${length(var.developers)}"
}
