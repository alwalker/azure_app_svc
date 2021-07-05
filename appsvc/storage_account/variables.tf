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

variable "kind" {
  type = string
  default = "StorageV2"
}
variable "tier" {
  type = string
  default = "Standard"
}
variable "replication_type" {
  type = string
  default = "LRS"
}
variable "min_tls_version" {
  type = string
  default = "TLS1_2"
}
variable "allow_blob_public_access" {
  type = bool
  default = true
}
variable "delete_retention_days" {
  type = number
  default = 7
}
variable "access_tier" {
  type = string
  default = "Hot"
}
variable "large_file_share_enabled" {
  type = bool
  default = false
}

variable "private_container_names" {
  type = list
}

variable "log_analytics_workspace_id" {
  type = string
}
