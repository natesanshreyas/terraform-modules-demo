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

# ── Existing Resource Group (data source) ────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

# ── Existing Key Vault (data source) ─────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = "redis-snow-tf-agent"
  location            = "eastus2"
  resource_group_name = data.azurerm_resource_group.rg.name

  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  enable_non_ssl_port = false

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id   = "RITM0010058"
  }
}

# ── Store Redis Connection String in Key Vault ───────────────────────────────
resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string
  key_vault_id = data.azurerm_key_vault.kv.id

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id   = "RITM0010058"
  }
}
