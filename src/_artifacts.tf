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
    certificate = var.tls_enabled ? {
      cert             = google_sql_database_instance.main.server_ca_cert[0].cert
      create_time      = google_sql_database_instance.redis.server_ca_certs[0].create_time
      expiration_time  = google_sql_database_instance.redis.server_ca_certs[0].expiration_time
      sha1_fingerprint = google_sql_database_instance.redis.server_ca_certs[0].sha1_fingerprint
    } : null
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
