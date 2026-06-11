locals {
  infrastructure = {
    name = google_sql_database_instance.main.id
  }

  security = {}

  authentication = {
    username = google_sql_user.root.name
    password = google_sql_user.root.password
    hostname = google_sql_database_instance.main.private_ip_address
    port     = 5432
  }
  specs_rdbms = {
    engine  = "PostgreSQL"
    version = google_sql_database_instance.main.database_version
  }
}

resource "massdriver_artifact" "authentication" {
  field    = "authentication"
  name     = "'Root' Postgres user credentials for: ${google_sql_database_instance.main.self_link}"
  artifact = jsonencode(
    {
      authentication = local.authentication
      infrastructure = local.infrastructure
      security       = local.security
      specs = {
        rdbms = local.specs_rdbms
      }
    }
  )
}
