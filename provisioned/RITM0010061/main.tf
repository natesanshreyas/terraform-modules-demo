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

# ── Existing Resource Group ──────────────────────────────────────────────────
data "azurerm_resource_group" "existing" {
  name = "snow-tf-agent-rg"
}

# ── Existing Key Vault ───────────────────────────────────────────────────────
data "azurerm_key_vault" "existing" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = "redis-snow-tf-agent"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010061"
  }
}

# ── Store Redis Connection String in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.existing.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    ticket_id   = "RITM0010061"
    cost_center = "CC-PLATFORM-001"
  }
}
