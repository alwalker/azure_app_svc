locals {
  webhook_domain = replace(azurerm_app_service.main.default_site_hostname, "azurewebsites.net", "scm.azurewebsites.net")
}

resource "azurerm_app_service" "main" {
  name                = "app-${var.base_name}-${var.name}-${var.env}"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  app_service_plan_id = var.plan_id

  client_affinity_enabled = var.client_affinity_enabled
  https_only              = true
  enabled = var.enabled

  identity {
    type = "SystemAssigned"
  }

  app_settings            = var.app_settings

  site_config {
    always_on        = var.always_on
    ftps_state       = "Disabled"
    linux_fx_version = "DOCKER|${var.registry_name}.azurecr.io/${var.container_image_name}:${var.container_image_tag}"
    health_check_path = var.health_check_path
    min_tls_version = var.min_tls_version
    http2_enabled = var.http2_enabled
    use_32_bit_worker_process = var.use_32_bit_worker_process
    websockets_enabled = var.websockets_enabled
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 2
        retention_in_mb   = 35
      }
    }
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
  target_resource_id = azurerm_app_service.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "AppServiceHTTPLogs"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServicePlatformLogs"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceConsoleLogs"
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

  log {
    category = "AppServiceAntivirusScanAuditLogs"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceAppLogs"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceFileAuditLogs"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceAuditLogs"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AppServiceIPSecAuditLogs"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

output "hostname" {
  value = azurerm_app_service.main.default_site_hostname
}
output "identity" {
  value = azurerm_app_service.main.identity.0.principal_id
}
output "tenant" {
  value = azurerm_app_service.main.identity.0.tenant_id
}
output "outbound_ips" {
  value = azurerm_app_service.main.possible_outbound_ip_address_list
}