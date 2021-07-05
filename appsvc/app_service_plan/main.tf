resource "azurerm_app_service_plan" "main" {
  name                = "plan-${var.base_name}-${var.env}"
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  kind     = var.kind
  reserved = var.reserved
  sku {
    tier = var.tier
    size = var.size
  }

  tags = { for k, v in var.default_tags : k => v }
} 

resource "azurerm_monitor_diagnostic_setting" "plan" {
  name               = "diag-plan-${var.base_name}-${var.env}"
  target_resource_id = azurerm_app_service_plan.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

output "plan_id" {
  value = azurerm_app_service_plan.main.id
}
