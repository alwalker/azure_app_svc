locals {
  priv_cidr = "10.0.1.0/24"
  pub_cidr  = "10.0.2.0/24"
  app_service_cidr = "10.0.3.0/24"
}

resource "azurerm_network_security_group" "priv" {
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  name = "nsg-priv"

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_network_security_group" "pub" {
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  name = "nsg-pub"

  security_rule {
    name                       = "AllowSSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "22"
    source_port_range          = "*"
    destination_address_prefix = "*"
    source_address_prefix      = "*"
  }

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_network_security_group" "app_service" {
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  name = "nsg-app-service"

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "80"
    source_port_range          = "*"
    destination_address_prefix = "*"
    source_address_prefix      = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_port_range          = "*"
    destination_address_prefix = "*"
    source_address_prefix      = "*"
  }

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_virtual_network" "main" {
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  name          = "vnet-${var.base_name}-${var.env}"
  address_space = ["10.0.0.0/16"]

  tags = { for k, v in var.default_tags : k => v }
}

resource "azurerm_subnet" "pub" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  name             = "snet-pub"
  address_prefixes = [local.pub_cidr]
  service_endpoints = [ "Microsoft.Storage" ]
}
resource "azurerm_subnet_network_security_group_association" "pub" {
  subnet_id                 = azurerm_subnet.pub.id
  network_security_group_id = azurerm_network_security_group.pub.id
}
resource "azurerm_subnet" "priv" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  name             = "snet-priv"
  address_prefixes = [local.priv_cidr]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints = [ "Microsoft.Storage" ]
}
resource "azurerm_subnet_network_security_group_association" "priv" {
  subnet_id                 = azurerm_subnet.priv.id
  network_security_group_id = azurerm_network_security_group.priv.id
}
resource "azurerm_subnet" "app_service" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name

  name             = "snet-app_service"
  address_prefixes = [local.app_service_cidr]
  service_endpoints = [ "Microsoft.Storage" ]

  delegation {
    name = "delegation"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name = "Microsoft.Web/serverFarms"
    }
  }
}
resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pgvnetlink-${var.base_name}-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "stvnetlink-${var.base_name}-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name

  tags = { for k, v in var.default_tags : k => v }
}
resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "redisvnetlink-${var.base_name}-${var.env}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.main.id

  tags = { for k, v in var.default_tags : k => v }
}

output "pub_subnet_id" {
  value = azurerm_subnet.pub.id
}
output "priv_subnet_id" {
  value = azurerm_subnet.priv.id
}
output "app_svc_subnet_id" {
  value = azurerm_subnet.app_service.id
}
output "postgres_zone_id" {
  value = azurerm_private_dns_zone.postgres.id
}
output "postgres_zone_name" {
  value = azurerm_private_dns_zone.postgres.name
}
output "storage_zone_id" {
  value = azurerm_private_dns_zone.storage.id
}
output "storage_zone_name" {
  value = azurerm_private_dns_zone.storage.name
}
output "redis_zone_id" {
  value = azurerm_private_dns_zone.redis.id
}
output "redis_zone_name" {
  value = azurerm_private_dns_zone.redis.name
}