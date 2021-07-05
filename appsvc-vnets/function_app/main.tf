locals {
  webhook_domain = replace(azurerm_function_app.main.default_hostname, "azurewebsites.net", "scm.azurewebsites.net")
  fd_name = "fd-${var.base_name}-${var.name}-${var.env}"
  fd_backend_1 = "backend-${replace(var.azure_region, " ", "")}"
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

  app_settings            = merge({
    WEBSITE_DNS_SERVER="168.63.129.16",
    WEBSITE_VNET_ROUTE_ALL="1"},
    var.app_settings
  )
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

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id  = azurerm_function_app.main.id
  subnet_id       = var.subnet_id
}

resource "azurerm_container_registry_webhook" "main" {
  name                = "whk${var.base_name}${var.name}${var.env}"
  location            = var.acr_azure_region
  resource_group_name = var.acr_resource_group_name
  registry_name       = var.registry_name

  service_uri = "https://${azurerm_function_app.main.site_credential.0.username}:${azurerm_function_app.main.site_credential.0.password}@${local.webhook_domain}/docker/hook"
  status      = var.webhook_status
  scope       = "${var.container_image_name}:${var.container_image_tag}"
  actions     = var.webhook_actions

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

resource "random_id" "kv_id" {
  byte_length = 32
  prefix = "kv-${var.base_name}-${var.name}-${var.env}-"
}
resource "azurerm_key_vault" "main" {
  name                        = substr(random_id.kv_id.hex, 0, 24)
  location                    = var.azure_region
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = azurerm_function_app.main.identity.0.tenant_id
  soft_delete_retention_days  = var.retention_in_days
  purge_protection_enabled    = var.purge_protection_enabled

  sku_name = var.sku_name

  dynamic "access_policy" {
    for_each = var.access_policies

    content {
      tenant_id = azurerm_function_app.main.identity.0.tenant_id
      object_id = coalesce(access_policy.value["object_id"], azurerm_function_app.main.identity.0.principal_id)

      secret_permissions = access_policy.value["secret_permissions"]
      key_permissions = access_policy.value["key_permissions"]
      storage_permissions = access_policy.value["storage_permissions"]
      certificate_permissions = access_policy.value["certificate_permissions"]
    }
  }

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_frontdoor" "main" {
  name                = local.fd_name
  resource_group_name = var.resource_group_name
  tags = { for k, v in var.default_tags : k => v }

  backend_pools_send_receive_timeout_seconds = var.fd_backend_pool_timeout
  enforce_backend_pools_certificate_name_check = var.fd_enforce_backend_pools_certificate_name_check
  load_balancer_enabled = var.load_balancer_enabled

  backend_pool {
    name = local.fd_backend_1
    backend {
      enabled = true
      host_header = azurerm_function_app.main.default_hostname
      address     = azurerm_function_app.main.default_hostname
      http_port   = 80
      https_port  = 443
      priority = 1
      weight = 50
    }

    load_balancing_name = "mylb"
    health_probe_name   = "healthprobe"
  }
  backend_pool_health_probe {
    name = "healthprobe"
    enabled = true
    path = var.health_check_path
    protocol = var.health_check_protocol
    probe_method = var.health_check_verb
    interval_in_seconds = var.health_check_interval
  }
  backend_pool_load_balancing {
    name = "mylb"
    sample_size = var.fd_lb_sample_size
    successful_samples_required = var.fd_lb_successful_samples_required
    additional_latency_milliseconds = var.fd_lb_additional_latency_milliseconds
  }  

  frontend_endpoint {
    name                              = "frontend"
    host_name                         = "${local.fd_name}.azurefd.net"
    session_affinity_enabled = false
    session_affinity_ttl_seconds = 0

    custom_https_provisioning_enabled = false #will eventually be true
    # azurerm_frontdoor_custom_https_configuration {
    # }
  }

  ######DYNAIMC BLOCKS WITH CNAMES GO HERE########

  routing_rule {
    name               = "httpredirect"
    enabled = true
    frontend_endpoints = ["frontend"]
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      redirect_type = "PermanentRedirect"
    }
  }
   routing_rule {
    name               = "https"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["frontend"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = local.fd_backend_1
      cache_enabled = var.cache_enabled
      cache_use_dynamic_compression = var.dynamic_cache_enabled
      cache_query_parameter_strip_directive = var.cache_query_parameter_strip_directive
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "frontdoor" {
  name               = "diag-fd-${var.base_name}-${var.name}-${var.env}"
  target_resource_id = azurerm_frontdoor.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "FrontdoorAccessLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "FrontdoorWebApplicationFirewallLog"
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
output "identity" {
  value = azurerm_function_app.main.identity.0.principal_id
}
output "outbound_ip_addresses" {
  value = azurerm_function_app.main.outbound_ip_addresses
}
