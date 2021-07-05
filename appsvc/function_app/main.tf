locals {
  webhook_domain = replace(azurerm_function_app.main.default_hostname, "azurewebsites.net", "scm.azurewebsites.net")
}

resource "azurerm_function_app" "main" {
  name                = "func-${var.base_name}-${var.name}-${var.env}"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  app_service_plan_id = var.plan_id

  client_affinity_enabled = var.client_affinity_enabled  
  https_only              = true
  enabled = var.enabled
  storage_account_name = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  os_type = "linux"

  identity {
    type = "SystemAssigned"
  }

  app_settings            = var.app_settings
  
  site_config {
    always_on        = var.always_on
    ftps_state       = "Disabled"
    linux_fx_version = "DOCKER|${var.registry_name}.azurecr.io/${var.container_image_name}:${var.container_image_tag}"
    min_tls_version = var.min_tls_version
    http2_enabled = var.http2_enabled
    use_32_bit_worker_process = var.use_32_bit_worker_process
    websockets_enabled = var.websockets_enabled
  }

  lifecycle {
    ignore_changes = [
      app_settings,
      site_config[0].linux_fx_version
    ]
  }

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "diag-func-${var.base_name}-${var.name}-${var.env}"
  target_resource_id = azurerm_function_app.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "FunctionAppLogs"
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

output "hostname" {
  value = azurerm_function_app.main.default_hostname
}
output "id" {
  value = azurerm_function_app.main.id
}
output "outbound_ip_addresses" {
  value = azurerm_function_app.main.outbound_ip_addresses
}
output "outbound_ips" {
  value = split(",", azurerm_function_app.main.possible_outbound_ip_addresses)
}
