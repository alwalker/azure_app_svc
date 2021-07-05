resource "random_id" "st_id" {
  byte_length = 32
  prefix = lower("st${var.base_name}${var.env}")
}
resource "azurerm_storage_account" "main" {
  name                     = substr(random_id.st_id.hex, 0, 24)
  resource_group_name      = var.resource_group_name
  location                 = var.azure_region

  account_tier             = var.tier
  account_kind = var.kind
  account_replication_type = var.replication_type
  access_tier = var.access_tier

  enable_https_traffic_only = true
  min_tls_version = var.min_tls_version
  allow_blob_public_access = var.allow_blob_public_access
  large_file_share_enabled = var.large_file_share_enabled

  blob_properties {
    delete_retention_policy {
      days = var.delete_retention_days      
    }
  }

  tags                     = { for k, v in var.default_tags : k => v }
}
resource "azurerm_storage_container" "private_containers" {
  count = length(var.private_container_names)

  name                  = element(var.private_container_names, count.index)
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.main.name
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name = "diag-st-blob-${var.base_name}-${var.env}"
  target_resource_id = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageWrite"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageDelete"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "Transaction"
    enabled = true

    retention_policy {
      enabled = false
    }
  }
  metric {
          category = "Capacity"
          enabled  = false

          retention_policy {
              enabled = false 
            }
        }
}

output "name" {
  value = azurerm_storage_account.main.name
}
output "key" {
  value = azurerm_storage_account.main.primary_access_key
}
output "connection_string" {
  value = azurerm_storage_account.main.primary_connection_string 
}