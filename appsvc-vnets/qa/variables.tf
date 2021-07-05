variable "azure_region" {
  type    = string
  default = "East US 2"
}

variable "base_name" {
  type    = string
  default = "myapp"
}

variable "env" {
  type = string
  default = "qa"
}

variable "database_login" {
  type = string
  default = "fgadmin"
}

variable "database_password" {
  type = string
}

variable "database_name" {
  type = string
  default = "myapp"
}

variable "acr_password" {
  type = string
}

variable "acr_name" {
  type = string
  default = "alwtest"
}

variable "default_tags" {
  type = map
  default = {
    terraform = "true"
  }
}