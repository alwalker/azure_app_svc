variable "azure_region" {
  type = string
}
variable "base_name" {
  type = string
}
variable "env" {
  type = string
}
variable "name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "default_tags" {
  type = map
}

variable "plan_id" {
  type = string
}
variable "storage_account_access_key" {
  type = string
}
variable "storage_account_name" {
  type = string
}
variable "registry_name" {
  type = string
}
variable "container_image_name" {
  type = string
}
variable "container_image_tag" {
  type = string
}
variable "app_settings" {
  type = map(string)
}
variable "client_affinity_enabled" {
  type = bool
  default = false
}
variable "enabled" {
  type = bool
  default = true
}
variable "always_on" {
  type = bool
  default = true
}
variable "min_tls_version" {
  type = string
  default = "1.2"
}
variable "http2_enabled" {
  type = bool
  default = false
}
variable "use_32_bit_worker_process" {
  type = bool
  default = true
}
variable "websockets_enabled" {
  type = bool
  default = false
}

variable "webhook_status" {
  type = string
  default = "enabled"
}
variable "webhook_actions" {
  type = list
  default = ["push"]
}

variable "log_analytics_workspace_id" {
  type = string
}