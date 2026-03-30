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
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  sku_name            = "Standard"
  capacity            = 1
  family              = "C"
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id  = "RITM0010050"
    project    = "snow-tf-agent"
  }
}

output "redis_hostname" {
  value = module.redis.hostname
}
