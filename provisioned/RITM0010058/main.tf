terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ── Data Sources: Existing RG & Key Vault ────────────────────────────────────
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "existing" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = var.location
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = {
    cost_center = var.cost_center
    ticket_id  = "RITM0010058"
  }
}

# ── Store Redis Connection String in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.existing.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    cost_center = var.cost_center
    ticket_id  = "RITM0010058"
  }
}
