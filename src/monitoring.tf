
locals {
  metrics = {
    "cpu" = {
      metric    = "cloudsql.googleapis.com/database/cpu/utilization"
      resource  = "cloudsql_database"
      threshold = 0.6
    }
    "disk" = {
      metric    = "cloudsql.googleapis.com/database/disk/utilization"
      resource  = "cloudsql_database"
      threshold = 0.6
    }
    "memory" = {
      metric    = "cloudsql.googleapis.com/database/memory/utilization"
      resource  = "cloudsql_database"
      threshold = 0.8
    }
  }
}

module "alarm_channel" {
  source      = "massdriver-cloud/gcp-alarm-channel/massdriver"
  md_metadata = var.md_metadata
}

module "database_cpu_alarm" {
  source                  = "massdriver-cloud/gcp-metric-alarm/massdriver"
  notification_channel_id = module.alarm_channel.id
  md_metadata             = var.md_metadata
  display_name            = "CPU Utilization"
  message                 = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: CPU Utilization over threshold ${local.metrics["cpu"].threshold * 100}%"
  alarm_name              = "${google_sql_database_instance.main.name}-highCPU"
  metric_type             = local.metrics["cpu"].metric
  resource_type           = local.metrics["cpu"].resource
  threshold               = local.metrics["cpu"].threshold
  comparison              = "COMPARISON_GT"
  duration                = 60
}


module "database_disk_alarm" {
  source                  = "massdriver-cloud/gcp-metric-alarm/massdriver"
  notification_channel_id = module.alarm_channel.id
  md_metadata             = var.md_metadata
  display_name            = "Disk Capacity"
  message                 = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: Disk capacity over threshold ${local.metrics["disk"].threshold * 100}%"
  alarm_name              = "${google_sql_database_instance.main.name}-highDisk"
  metric_type             = local.metrics["disk"].metric
  resource_type           = local.metrics["disk"].resource
  threshold               = local.metrics["disk"].threshold
  comparison              = "COMPARISON_GT"
  duration                = 60
}

module "database_memory_alarm" {
  source                  = "massdriver-cloud/gcp-metric-alarm/massdriver"
  notification_channel_id = module.alarm_channel.id
  md_metadata             = var.md_metadata
  display_name            = "Memory Capacity"
  message                 = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: Memory capacity over threshold ${local.metrics["memory"].threshold * 100}%"
  alarm_name              = "${google_sql_database_instance.main.name}-highMemory"
  metric_type             = local.metrics["memory"].metric
  resource_type           = local.metrics["memory"].resource
  threshold               = local.metrics["memory"].threshold
  comparison              = "COMPARISON_GT"
  duration                = 60
}
