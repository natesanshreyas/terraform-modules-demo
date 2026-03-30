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

# ── Existing Resource Group (reference) ──────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

# ── Existing Key Vault (reference) ───────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Azure Cache for Redis ────────────────────────────────────────────────────
module "redis" {
  source = "../../modules/redis-cache"

  name                = "redis-snow-tf-agent"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"

  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  enable_non_ssl_port = false

  cost_center = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010044"
  }
}

# ── Store Redis connection string in existing Key Vault ──────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.kv.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  tags = {
    ticket_id  = "RITM0010044"
    cost_center = "CC-PLATFORM-001"
  }
}

output "redis_id" {
  value = module.redis.redis_cache_id
}
