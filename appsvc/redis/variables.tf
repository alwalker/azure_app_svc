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

variable "sku" {
  type = string
  default = "Standard"
}
variable "capacity" {
  type = number
  default = 0
}
variable "family" {
  type = string
  default = "C"
}
variable "shard_count" {
  type = number
  default = 0
}
variable "maxmemory_policy" {
  type = string
  default = "noeviction"
}
variable "minimum_tls_version" {
  type = string
  default = "1.2"
}
variable "public_network_access_enabled" {
  type = bool
  default = false
}
variable "patch_day_of_week" {
  type = string
  default = "Saturday"
}
variable "patch_start_hour_utc" {
  type = string
  default = "7"
}
