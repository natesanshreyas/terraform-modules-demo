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
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# ── Existing Key Vault ───────────────────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = var.redis_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  environment         = var.environment
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
    project   = "snow-tf-agent"
  }
}

# ── Store Redis connection string in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.kv.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    ticket_id   = var.ticket_id
    cost_center = var.cost_center
  }
}

output "redis_id" {
  value = module.redis.redis_id
}
