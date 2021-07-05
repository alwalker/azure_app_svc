output "database_host" {
  value = module.database.server_fqdn
}
output "database_name" {
  value = var.database_name
}
output "database_user" {
  value = var.database_login
}
output "database_password" {
  value = var.database_password
}
output "database_connection_string" {
  value = module.database.connection_string
}

output "storage_account_name" {
    value = module.storage-account.name
}
output "storage_account_key" {
    value = module.storage-account.key
}

output "redis_hostname" {
  value = module.redis.hostname
}
output "redis_port" {
  value = module.redis.port
}
output "redis_key" {
  value = module.redis.key
}
output "redis_connection_string" {
  value = module.redis.connection_string
}

output "backend_url" {
  value = "https://${module.backend.hostname}"
}
output "frontend_url" {
  value = "https://${module.frontend.hostname}"
}
