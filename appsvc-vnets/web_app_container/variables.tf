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
variable "subnet_id" {
  type = string
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
  default = false
}
variable "websockets_enabled" {
  type = bool
  default = false
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
variable "health_check_path" {
  type = string
  default = "/health"
}
variable "app_settings" {
  type = map(string)
}

variable "acr_azure_region" {
  type = string
}
variable "acr_resource_group_name" {
  type = string
}
variable "webhook_status" {
  type = string
  default = "enabled"
}
variable "webhook_actions" {
  type = list
  default = ["push"]
}

variable "retention_in_days" {
  type = number
  default = 7
}
variable "purge_protection_enabled" {
  type = bool
  default = false
}
variable "sku_name" {
  type = string
  default = "standard"
}
variable "access_policies" {
  type = map(object({
    object_id = string
    secret_permissions = list(string)
    key_permissions = list(string)
    storage_permissions = list(string)
    certificate_permissions = list(string)
  }))
}

variable "fd_backend_pool_timeout" {
  type = number
  default = 60
}
variable "fd_enforce_backend_pools_certificate_name_check" {
  type = bool
  default = true
}
variable "load_balancer_enabled" {
  type = bool
  default = true
}
variable "health_check_protocol" {
  type = string
  default = "Https"
}
variable "health_check_verb" {
  type = string
  default = "HEAD"
}
variable "health_check_interval" {
  type = number
  default = 30
}
variable "fd_lb_sample_size" {
  type = number
  default = 4
}
variable "fd_lb_successful_samples_required" {
  type = number
  default = 2
}
variable "fd_lb_additional_latency_milliseconds" {
  type = number
  default = 0
}
variable "cache_enabled" {
  type = bool
  default = false
}
variable "dynamic_cache_enabled" {
  type = bool
  default = false
}
variable "cache_query_parameter_strip_directive" {
  type = string
  default = "StripAll"
}

variable "log_analytics_workspace_id" {
  type = string
}
