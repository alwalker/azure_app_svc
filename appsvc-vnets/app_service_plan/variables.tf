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
  default = "linux"
}
variable "reserved" {
  type = bool
  default = true
}
variable "tier" {
  type = string
  default = "Standard"
}
variable "size" {
  type = string
  default = "S2"
}


variable "autoscale_capacity_default" {
  type = string
  default = "1"
}
variable "autoscale_capacity_min" {
  type = string
  default = "1"
}
variable "autoscale_capacity_max" {
  type = string
  default = "10"
}
variable "autoscale_scaleup_trigger_period" {
  type = string
  default = "PT1M"
}
variable "autoscale_scaleup_trigger_window" {
  type = string
  default = "PT5M"
}
variable "autoscale_scaleup_trigger_statistic" {
  type = string
  default = "Average"
}
variable "autoscale_scaleup_trigger_aggregation" {
  type = string
  default = "Average"
}
variable "autoscale_scaleup_trigger_operator" {
  type = string
  default = "GreaterThan"
}
variable "autoscale_scaleup_trigger_threshold" {
  type = string
  default = "75"
}
variable "autoscale_scaleup_action_amount" {
  type = string
  default = "1"
}
variable "autoscale_scaleup_action_cooldown" {
  type = string
  default = "PT1M"
}
variable "autoscale_scaledown_trigger_period" {
  type = string
  default = "PT1M"
}
variable "autoscale_scaledown_trigger_window" {
  type = string
  default = "PT5M"
}
variable "autoscale_scaledown_trigger_statistic" {
  type = string
  default = "Average"
}
variable "autoscale_scaledown_trigger_aggregation" {
  type = string
  default = "Average"
}
variable "autoscale_scaledown_trigger_operator" {
  type = string
  default = "LessThan"
}
variable "autoscale_scaledown_trigger_threshold" {
  type = string
  default = "25"
}
variable "autoscale_scaledown_action_amount" {
  type = string
  default = "1"
}
variable "autoscale_scaledown_action_cooldown" {
  type = string
  default = "PT1M"
}

variable "log_analytics_workspace_id" {
  type = string
}