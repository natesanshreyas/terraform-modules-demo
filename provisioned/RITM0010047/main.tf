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

# ── Reference existing Resource Group ────────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

# ── Reference existing Key Vault ─────────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = "redis-snow-tf-agent"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  environment         = "prod"
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

# ── Store Redis connection string in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.kv.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    ticket_id  = var.ticket_id
    cost_center = var.cost_center
  }
}
