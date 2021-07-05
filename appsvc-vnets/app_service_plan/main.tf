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

resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "asc-plan-${var.base_name}-${var.env}"
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_app_service_plan.main.id

  profile {
    name = "CPU"

    capacity {
      default = var.autoscale_capacity_default
      minimum = var.autoscale_capacity_min
      maximum = var.autoscale_capacity_max
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.main.id
        time_grain         = var.autoscale_scaleup_trigger_period
        statistic          = var.autoscale_scaleup_trigger_statistic
        time_window        = var.autoscale_scaleup_trigger_window
        time_aggregation   = var.autoscale_scaleup_trigger_aggregation
        operator           = var.autoscale_scaleup_trigger_operator
        threshold          = var.autoscale_scaleup_trigger_threshold
        metric_namespace   = "Microsoft.Web/serverFarms"        
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = var.autoscale_scaleup_action_amount
        cooldown  = var.autoscale_scaleup_action_cooldown
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.main.id
        metric_namespace   = "Microsoft.Web/serverFarms"
        time_grain         = var.autoscale_scaledown_trigger_period
        statistic          = var.autoscale_scaledown_trigger_statistic
        time_window        = var.autoscale_scaledown_trigger_window
        time_aggregation   = var.autoscale_scaledown_trigger_aggregation
        operator           = var.autoscale_scaledown_trigger_operator
        threshold          = var.autoscale_scaledown_trigger_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = var.autoscale_scaledown_action_amount
        cooldown  = var.autoscale_scaledown_action_cooldown
      }
    }
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
resource "azurerm_monitor_diagnostic_setting" "autoscale" {
  name               = "diag-asc-plan-${var.base_name}-${var.env}"
  target_resource_id = azurerm_monitor_autoscale_setting.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "AutoscaleEvaluations"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AutoscaleScaleActions"
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

output "plan_id" {
  value = azurerm_app_service_plan.main.id
}
