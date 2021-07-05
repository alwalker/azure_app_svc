resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.base_name}-${var.env}"
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku

  enable_non_ssl_port = false
  minimum_tls_version = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled
  shard_count = var.shard_count

  redis_configuration {
    enable_authentication = true
    rdb_backup_enabled = false
    maxmemory_policy = var.maxmemory_policy
  }

  patch_schedule {
    day_of_week = var.patch_day_of_week
    start_hour_utc = var.patch_start_hour_utc
  }

  tags = { for k, v in var.default_tags : k => v }
}

output "hostname" {
  value = azurerm_redis_cache.main.hostname
}
output "port" {
  value = azurerm_redis_cache.main.ssl_port
}
output "key" {
  value = azurerm_redis_cache.main.primary_access_key
}
output "connection_string" {
  value = "rediss://admin:${urlencode(azurerm_redis_cache.main.primary_access_key)}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
}