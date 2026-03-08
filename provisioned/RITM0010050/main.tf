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

# ── Existing Resource Group (Data Source) ────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

# ── Existing Key Vault (Data Source) ─────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = "redis-snowtfagent-prod"
  location            = "eastus2"
  resource_group_name = data.azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010050"
  }
}

# ── Store Redis Connection String in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.kv.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    ticket_id  = "RITM0010050"
    cost_center = "CC-PLATFORM-001"
  }
}
