terraform {
  backend "azurerm" {
    resource_group_name  = "alw-workspace"
    storage_account_name = "alwstuff"
    container_name       = "tfstates"
    key                  = "example-appsvc.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.50.0"
    }
  }
}

provider "azurerm" {
  subscription_id = ""
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.base_name}-${var.env}-rg"
  location = var.azure_region

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.base_name}-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = { for k, v in var.default_tags : k => v }
}

module "storage-account" {
  source = "../storage_account"

  azure_region        = var.azure_region
  base_name           = replace(var.base_name, "/[^a-zA-Z0-9]/", "")
  env                 = replace(var.env, "/[^a-zA-Z0-9]/", "")
  resource_group_name = azurerm_resource_group.main.name

  private_container_names       = ["exampleblobs", "container2"]

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  default_tags        = var.default_tags
}

module "database" {
  source = "../database"

  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name

  database_login    = var.database_login
  database_password = var.database_password
  public_network_access_enabled = true
  allowed_ips = [module.backend.outbound_ips, module.frontend.outbound_ips, module.scheduled_jobs.outbound_ips]

  database_name = var.database_name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  default_tags = var.default_tags
}

module "redis" {
  source = "../redis"

  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name

  default_tags = var.default_tags
}

module "app_service" {
  source = "../app_service_plan"

  azure_region = var.azure_region
  base_name    = var.base_name
  env          = var.env
  resource_group_name = azurerm_resource_group.main.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  default_tags = var.default_tags
}
module "backend" {
  source = "../web_app_container"

  azure_region = var.azure_region
  base_name    = var.base_name
  env          = var.env
  resource_group_name = azurerm_resource_group.main.name
  name = "backend"

  plan_id = module.app_service.plan_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  registry_name = var.oci_reg_name
  container_image_name = "stress"
  container_image_tag   = var.env

  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.oci_reg_password
    DOCKER_REGISTRY_SERVER_URL      = "http://${var.oci_reg_name}"
    DOCKER_REGISTRY_SERVER_USERNAME = var.oci_reg_username
    DOCKER_ENABLE_CI = true
  }

  default_tags = var.default_tags
}
module "frontend" {
  source = "../web_app_container"

  azure_region = var.azure_region
  base_name    = var.base_name
  env          = var.env
  resource_group_name = azurerm_resource_group.main.name
  name = "frontend"

  plan_id = module.app_service.plan_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  registry_name = var.oci_reg_name
  container_image_name = "sample_frontend"
  container_image_tag   = var.env

  health_check_path = "/health"
  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.oci_reg_password
    DOCKER_REGISTRY_SERVER_URL      = "http://${var.oci_reg_name}"
    DOCKER_REGISTRY_SERVER_USERNAME = var.oci_reg_username
    DOCKER_ENABLE_CI = true
  }

  default_tags = var.default_tags
}

module "scheduled_jobs" {
  source = "../function_app"

  azure_region = var.azure_region
  base_name    = var.base_name
  env          = var.env
  resource_group_name = azurerm_resource_group.main.name
  name = "bgworkers"

  plan_id = module.app_service.plan_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_name = module.storage-account.name
  storage_account_access_key = module.storage-account.key

  registry_name = var.oci_reg_name
  container_image_name = "sample_frontend"
  container_image_tag   = var.env

  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.oci_reg_password
    DOCKER_REGISTRY_SERVER_URL      = "http://${var.oci_reg_name}"
    DOCKER_REGISTRY_SERVER_USERNAME = var.oci_reg_username
    DOCKER_ENABLE_CI = true
    WEBSITES_ENABLE_APP_SERVICE_STORAGE       = false
  }

  default_tags = var.default_tags
}
