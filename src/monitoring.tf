
locals {
  threshold_cpu    = 0.6
  threshold_disk   = 0.6
  threshold_memory = 0.8

  metrics = {
    "cpu" = {
      metric   = "cloudsql.googleapis.com/database/cpu/utilization"
      resource = "cloudsql_database"
    }
    "disk" = {
      metric   = "cloudsql.googleapis.com/database/disk/utilization"
      resource = "cloudsql_database"
    }
    "memory" = {
      metric   = "cloudsql.googleapis.com/database/memory/utilization"
      resource = "cloudsql_database"
    }
  }
}

module "database_cpu_alarm" {
  source                         = "./modules/monitoring-utilization-threshold"
  md_metadata                    = var.md_metadata
  message                        = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: CPU Utilization over threshold ${local.threshold_cpu * 100}%"
  alarm_notification_channel_grn = var.subnetwork.data.observability.alarm_notification_channel_grn

  alarm_name    = "${google_sql_database_instance.main.self_link}-highCPU"
  metric_type   = local.metrics["cpu"].metric
  resource_type = local.metrics["cpu"].resource
  threshold     = local.threshold_cpu
  period        = 60
  duration      = 60

  depends_on = [
    google_sql_database_instance.main
  ]
}


module "database_disk_alarm" {
  source                         = "./modules/monitoring-utilization-threshold"
  md_metadata                    = var.md_metadata
  message                        = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: Disk capacity over threshold ${local.threshold_disk * 100}%"
  alarm_notification_channel_grn = var.subnetwork.data.observability.alarm_notification_channel_grn

  alarm_name    = "${google_sql_database_instance.main.self_link}-highDisk"
  metric_type   = local.metrics["disk"].metric
  resource_type = local.metrics["disk"].resource
  threshold     = local.threshold_disk
  period        = 60
  duration      = 60

  depends_on = [
    google_sql_database_instance.main
  ]
}

module "database_memory_alarm" {
  source                         = "./modules/monitoring-utilization-threshold"
  md_metadata                    = var.md_metadata
  message                        = "Cloud SQL Postgres ${google_sql_database_instance.main.self_link}: Memory capacity over threshold ${local.threshold_memory * 100}%"
  alarm_notification_channel_grn = var.subnetwork.data.observability.alarm_notification_channel_grn

  alarm_name    = "${google_sql_database_instance.main.self_link}-highMemory"
  metric_type   = local.metrics["memory"].metric
  resource_type = local.metrics["memory"].resource
  threshold     = local.threshold_memory
  period        = 60
  duration      = 60

  depends_on = [
    google_sql_database_instance.main
  ]
}