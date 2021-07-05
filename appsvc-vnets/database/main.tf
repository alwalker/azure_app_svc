locals {
  server_name = lower("psql-${var.base_name}-${var.env}")
}

resource "azurerm_postgresql_server" "main" {
  name                = local.server_name
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  sku_name   = var.sku_name
  version    = var.engine_version
  storage_mb = var.storage_size

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup
  auto_grow_enabled            = var.auto_grow_enabled

  public_network_access_enabled    = var.public_network_access_enabled
  ssl_enforcement_enabled          = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.ssl_minimal_tls_version_enforced

  administrator_login          = var.database_login
  administrator_login_password = var.database_password

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_postgresql_database" "main" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.main.name

  charset   = var.charset
  collation = var.collation
}

resource "azurerm_private_endpoint" "main" {
  name                = "pep-psql-${var.base_name}-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.azure_region
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-psql-${var.base_name}-${var.env}"
    private_connection_resource_id = azurerm_postgresql_server.main.id
    subresource_names              = [ "postgresqlServer" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = var.dns_zone_name
    private_dns_zone_ids = [ var.dns_zone_id ]
  }

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "diag-psql-${var.base_name}-${var.env}"
  target_resource_id = azurerm_postgresql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "PostgreSQLLogs"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "QueryStoreRuntimeStatistics"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "QueryStoreWaitStatistics"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

output "server_id" {
  value = azurerm_postgresql_server.main.id
}
output "server_name" {
  value = azurerm_postgresql_server.main.name
}
output "server_fqdn" {
  value = azurerm_postgresql_server.main.fqdn
}

output "database_id" {
  value = azurerm_postgresql_database.main.id
}

output "connection_string" {
  value = "postgres://${var.database_login}%40${local.server_name}:${var.database_password}@${azurerm_postgresql_server.main.fqdn}:5432/${var.database_name}"
}
