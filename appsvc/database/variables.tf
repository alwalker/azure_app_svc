variable "azure_region" {
  type = string
}
variable "base_name" {
  type = string
}
variable "env" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "default_tags" {
  type = map
}

variable "sku_name" {
  type = string
  default = "GP_Gen5_2"
}
variable "engine_version" {
  type = string
  default = "11"
}
variable "storage_size" {
  type = number
  default = 102400
}
variable "backup_retention_days" {
  type = number
  default = 7
}
variable "geo_redundant_backup" {
  type = bool
  default = false
}
variable "database_login" {
  type = string
}
variable "database_password" {
  type = string
}
variable "allowed_ips" {
  type = list
}
variable "auto_grow_enabled" {
  type = bool
  default = true
}
variable "public_network_access_enabled" {
  type = bool
  default = false
}
variable "ssl_enforcement_enabled" {
  type = bool
  default = true
}
variable "ssl_minimal_tls_version_enforced" {
  type = string
  default = "TLS1_2"
}


variable "database_name" {
  type = string
}
variable "charset" {
  type = string
  default = "UTF8"
}
variable "collation" {
  type = string
  default = "English_United States.1252"
}

variable "log_analytics_workspace_id" {
  type = string
}
