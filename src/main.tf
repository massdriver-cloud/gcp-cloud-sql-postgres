
locals {
  # massdriver auth and regional cloud vars
  project_id         = var.gcp_authentication.data.project_id
  gcp_authentication = jsonencode(var.gcp_authentication.data)
  region             = var.subnetwork.specs.gcp.region
  # Cloud SQL expects the Global VPC GRN
  network_id = var.subnetwork.data.infrastructure.gcp_global_network_grn

  major_version_to_database_version = {
    "14.x"  = "POSTGRES_14"
    "13.x"  = "POSTGRES_13"
    "12.x"  = "POSTGRES_12"
    "11.x"  = "POSTGRES_11"
    "10.x"  = "POSTGRES_10"
    "9.6.x" = "POSTGRES_9_6"
  }
  database_version = lookup(local.major_version_to_database_version, var.engine_version, null)

  disk_human_readable_to_terraform = {
    "Solid State" = "PD_SSD"
    "Hard Disk"   = "PD_HDD"
  }
  disk_type = lookup(local.disk_human_readable_to_terraform, var.instance_configuration.disk_type, null)
  # These are internal-only sane defaults
  massdriver_maitenance_window_day   = "Tuesday"
  massdriver_maintenance_window_hour = 2
  maintenance_window_day_human_readable_to_terraform = {
    "Monday"    = 1
    "Tuesday"   = 2
    "Wednesday" = 3
    "Thursday"  = 4
    "Friday"    = 5
    "Saturday"  = 6
    "Sunday"    = 7
  }
  maintenance_window_day  = lookup(local.maintenance_window_day_human_readable_to_terraform, local.massdriver_maitenance_window_day, null)
  maintenance_window_hour = local.massdriver_maintenance_window_hour
}

resource "google_sql_database_instance" "main" {
  project          = local.project_id
  name             = var.md_metadata.name_prefix
  database_version = local.database_version
  region           = local.region

  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance
  # On newer versions of the provider, you must explicitly set
  # deletion_protection=false (and run terraform apply to write the field to state) in order
  # to destroy an instance. It is recommended to not set this field (or set it to true)
  # until you're ready to destroy the instance and its databases.
  deletion_protection = var.deletion_protection

  settings {
    tier = var.instance_configuration.tier
    # ALWAYS, NEVER, ON_DEMAND
    activation_policy = "ALWAYS"
    availability_type = "REGIONAL"
    user_labels       = var.md_metadata.default_tags

    ip_configuration {
      require_ssl     = var.tls_enabled
      ipv4_enabled    = false
      private_network = local.network_id
    }

    backup_configuration {
      # cannot be used with PostgreSQL
      binary_log_enabled             = false
      enabled                        = true
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.database_configuration.retained_backup_count
        # if the unit is COUNT then the above is number of backups to keep
        retention_unit = "COUNT"
      }
    }

    insights_config {
      query_insights_enabled = var.database_configuration.query_insights_enabled
      # double the default
      query_string_length     = 2000
      record_application_tags = false
      record_client_address   = false
    }

    disk_autoresize = false
    disk_size       = var.instance_configuration.disk_size
    disk_type       = local.disk_type
    # TF docs say this is the only option for pricing_plan
    pricing_plan = "PER_USE"

    maintenance_window {
      day          = local.maintenance_window_day
      hour         = local.maintenance_window_hour
      update_track = "stable"
    }
  }


  lifecycle {
    ignore_changes = [
      # This allows for disk resizng, borrowed from the docs
      # We might want to gaurd against this and disable auto resize
      # then remove this lifecycle hook
      settings[0].disk_size,
      # ignores changes to existing infrastructure
      settings[0].ip_configuration[0].require_ssl,
    ]
  }
  depends_on = [module.apis]
}


# ------------------------------------------------------------------------------
# CREATE A DATABASE
# ------------------------------------------------------------------------------

resource "google_sql_database" "default" {
  depends_on = [google_sql_database_instance.main]
  name       = "default"
  project    = local.project_id
  instance   = google_sql_database_instance.main.name
  # these are the only values supported for Postgres at the time
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

resource "random_password" "root_user_password" {
  length  = 10
  special = false
}

resource "google_sql_user" "root" {
  depends_on = [google_sql_database.default]
  project    = local.project_id
  name       = var.username
  instance   = google_sql_database_instance.main.name
  # Postgres users don't have hosts, so the API will ignore this value which causes Terraform to attempt
  # to recreate the user each time.
  # See https://github.com/terraform-providers/terraform-provider-google/issues/1526 for more information.
  host     = null
  password = random_password.root_user_password.result
}
