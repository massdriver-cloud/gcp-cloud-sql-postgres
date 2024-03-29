locals {
  data_infrastructure = {
    name = google_sql_database_instance.main.id
  }

  data_security = {}

  data_authentication = {
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
  field                = "authentication"
  provider_resource_id = google_sql_database_instance.main.self_link
  name                 = "'Root' Postgres user credentials for: ${google_sql_database_instance.main.self_link}"
  artifact = jsonencode(
    {
      data = {
        authentication = local.data_authentication
        infrastructure = local.data_infrastructure
        security       = local.data_security
      }
      specs = {
        rdbms = local.specs_rdbms
      }
    }
  )
}
