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
  name = "snow-tf-agent-rg"
}

# ── Existing Service Bus Namespace ───────────────────────────────────────────
data "azurerm_servicebus_namespace" "sb" {
  name                = "snowtfagentbus"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Existing Key Vault ───────────────────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Function App Service Plan ────────────────────────────────────────────────
module "function_plan" {
  source = "../../modules/service-plan"

  name                = "asp-snowtf-func-dev"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"

  environment  = "dev"
  cost_center = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010048"
  }
}

# ── Azure Function App ───────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                = "func-snowtf-sb-processor"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  service_plan_id     = module.function_plan.id

  key_vault_id            = data.azurerm_key_vault.kv.id
  service_bus_namespace   = data.azurerm_servicebus_namespace.sb.name

  environment  = "dev"
  cost_center = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010048"
  }
}
