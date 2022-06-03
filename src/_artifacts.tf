locals {
  data_infrastructure = {
    grn = google_sql_database_instance.main.self_link
  }

  data_security = {}

  data_authentication = {
    username = google_sql_user.root.name
    password = google_sql_user.root.password
    hostname = google_sql_database_instance.main.private_ip_address
    port     = "5432"
  }
  specs_rdbms = {
    engine  = "PostgreSQL"
    version = google_sql_database_instance.main.settings[0].version
  }
}

resource "massdriver_artifact" "authentication" {
  field                = "authentication"
  provider_resource_id = google_sql_database_instance.main.self_link
  type                 = "postgresql-authentication"
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
