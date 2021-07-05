terraform {
  backend "azurerm" {
    resource_group_name  = "alw-workspace"
    storage_account_name = "alwstuff"
    container_name       = "tfstates"
    key                  = "example-qa.tfstate"
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

module "vnet" {
  source = "../vnet"

  azure_region        = var.azure_region
  base_name           = replace(var.base_name, "/[^a-zA-Z0-9]/", "")
  env                 = replace(var.env, "/[^a-zA-Z0-9]/", "")
  resource_group_name = azurerm_resource_group.main.name
  default_tags        = var.default_tags
}

module "storage-account" {
  source = "../storage_account"

  azure_region        = var.azure_region
  base_name           = replace(var.base_name, "/[^a-zA-Z0-9]/", "")
  env                 = replace(var.env, "/[^a-zA-Z0-9]/", "")
  resource_group_name = azurerm_resource_group.main.name

  allowed_subnets = [module.vnet.priv_subnet_id, module.vnet.pub_subnet_id]
  
  private_container_names       = ["exampleblobs", "container2"]

  subnet_id = module.vnet.priv_subnet_id
  dns_zone_id = module.vnet.storage_zone_id
  dns_zone_name = module.vnet.storage_zone_name

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

  database_name = var.database_name

  subnet_id = module.vnet.priv_subnet_id
  dns_zone_id = module.vnet.postgres_zone_id
  dns_zone_name = module.vnet.postgres_zone_name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  default_tags = var.default_tags
}

module "redis" {
  source = "../redis"

  azure_region        = var.azure_region
  base_name           = var.base_name
  env                 = var.env
  resource_group_name = azurerm_resource_group.main.name

  subnet_id = module.vnet.priv_subnet_id
  dns_zone_id = module.vnet.redis_zone_id
  dns_zone_name = module.vnet.redis_zone_name

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
  subnet_id = module.vnet.app_svc_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  registry_name = var.acr_name
  container_image_name = "stress"
  container_image_tag   = var.env

  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.acr_password
    DOCKER_REGISTRY_SERVER_URL      = "https://${var.acr_name}.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = var.acr_name
    DOCKER_ENABLE_CI = true
  }

  acr_azure_region = var.azure_region
  acr_resource_group_name    = "alw-workspace"

  access_policies = {
    this = {
      object_id = null #stupid hack until TF has optional variables
      secret_permissions = ["Get"]
      key_permissions = []
      storage_permissions = []
      certificate_permissions = []
    },
    andrew = {
      object_id = "GUID" 
      key_permissions = ["Get", "Create", "Delete", "List", "Update"]
      secret_permissions = ["Get", "Set", "Delete", "List"]
      storage_permissions = ["Get", "Set", "Delete", "List", "Update"]
      certificate_permissions = ["Get", "Create", "Delete", "List", "Update"]
    }
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
  subnet_id = module.vnet.app_svc_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  registry_name = var.acr_name  
  container_image_name = "sample_frontend"
  container_image_tag   = var.env
  health_check_path = "/health"
  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.acr_password
    DOCKER_REGISTRY_SERVER_URL      = "https://${var.acr_name}.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = var.acr_name
    DOCKER_ENABLE_CI = true
  }

  acr_azure_region = var.azure_region
  acr_resource_group_name    = "alw-workspace"

  cache_enabled = true

  access_policies = {
    backend = {
      object_id = null #stupid hack until TF has optional variables
      secret_permissions = ["Get"]
      key_permissions = []
      storage_permissions = []
      certificate_permissions = []
    },
    andrew = {
      object_id = "GUID" 
      key_permissions = ["Get", "Create", "Delete", "List", "Update"]
      secret_permissions = ["Get", "Set", "Delete", "List"]
      storage_permissions = ["Get", "Set", "Delete", "List", "Update"]
      certificate_permissions = ["Get", "Create", "Delete", "List", "Update"]
    }
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
  subnet_id = module.vnet.app_svc_subnet_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  storage_account_name = module.storage-account.name
  storage_account_access_key = module.storage-account.key

  registry_name = var.acr_name  
  container_image_name = "sample_frontend"
  container_image_tag   = var.env
  app_settings = {
    DOCKER_REGISTRY_SERVER_PASSWORD = var.acr_password
    DOCKER_REGISTRY_SERVER_URL      = "https://${var.acr_name}.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = var.acr_name
    DOCKER_ENABLE_CI = true
    WEBSITES_ENABLE_APP_SERVICE_STORAGE       = false
  }

  acr_azure_region = var.azure_region
  acr_resource_group_name    = azurerm_resource_group.main.name

  access_policies = {
    backend = {
      object_id = null #stupid hack until TF has optional variables
      secret_permissions = ["Get"]
      key_permissions = []
      storage_permissions = []
      certificate_permissions = []
    },
    andrew = {
      object_id = "GUID" 
      key_permissions = ["Get", "Create", "Delete", "List", "Update"]
      secret_permissions = ["Get", "Set", "Delete", "List"]
      storage_permissions = ["Get", "Set", "Delete", "List", "Update"]
      certificate_permissions = ["Get", "Create", "Delete", "List", "Update"]
    }
  }

  default_tags = var.default_tags
}










resource "azurerm_public_ip" "agw" {
  name                = "agwvmpip"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "agw" {
  name                = "${var.base_name}-${var.env}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = module.vnet.pub_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.agw.id
  }
}
resource "azurerm_virtual_machine" "agw" {
  name                  = "${var.base_name}-${var.env}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_region
  network_interface_ids = [azurerm_network_interface.agw.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "ubuntu"
  }
  os_profile_linux_config {    
    disable_password_authentication = true

    ssh_keys {
      path = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdwRhN07rL9TnrstKPuxeyLEfXebuLYPkXmevz7/0qRzSvdfRu2yujFalpgTbWZTZGmMeeEXWGiOM/B/4eOyhh4k1pIhx4+BQ3GeBZAhjuOINipW/BaT5OIrurZXV9M3XkxXpAacMw5TKb/pbBijNS8gsCGxrf3emyYMZlylwcbSO1b+3C93rco+w4LS5wPpTpZ8ng2VbeMn888KOrgLqzKLfZQ+fGpDhBHWdEhOxR/trrA7KsL8XoHRRW9U+HBsh2FJ77q/gE8JMVipiRtGpDfPKN9T3tl/PlAVXH465GbTbfjSWv32mXVQs/n5x+8DeXBcPajfffEaqEpX6MMmkA4deYJDGhYvbZcwEZavbr7X6fcdOOJ4lvAwLxXoxshCyOaT+2TZBNeN3gvg3aGZ0XVLgmo5tYVhiynz0DkPm7QkxZbhhtsojEPNkHs1lOQCt5Fsj/7WpFXoVAwNC7FFs22pMH+WvfUOcX85HSkWY6tZGVHAyUICHxH/NZzGlxdAs++NuKYqh5Nb7LdGHomrvSFl7wNekwkRcAYx3o86ButjMJkm76m8VVFACklU3ZW2JF/o4unmW9nA8d1XApgvFG0MDptimB0GMQ09Gh9PNFYU2qrUabkRkJZZtOFZTes5mLnliNGQF7NpQrW1yrdTqv4jO7E8e3wvn0PIrpAdP0MQ=="
    }
  }
}
