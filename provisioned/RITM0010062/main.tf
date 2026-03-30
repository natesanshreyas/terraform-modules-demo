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

  name                = "redis-snowtfagent-dev"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"

  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  enable_non_ssl_port = false

  environment = "dev"
  cost_center = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010062"
    project   = "snow-tf-agent"
  }
}

# ── Store Redis Connection String in Key Vault ───────────────────────────────
module "redis_secret" {
  source = "../../modules/key-vault-secret"

  key_vault_id = data.azurerm_key_vault.kv.id
  name         = "redis-connection-string"
  value        = module.redis.primary_connection_string

  content_type = "text/plain"

  tags = {
    ticket_id = "RITM0010062"
    cost_center = "CC-PLATFORM-001"
  }
}

output "redis_hostname" {
  value = module.redis.hostname
}
