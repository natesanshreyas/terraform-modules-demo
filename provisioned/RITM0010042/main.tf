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

# ── Existing Resource Group ────────────────────────────────────────────────
data "azurerm_resource_group" "existing" {
  name = "snow-tf-agent-rg"
}

# ── Existing Key Vault ─────────────────────────────────────────────────────
data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── Existing Service Bus Namespace ─────────────────────────────────────────
data "azurerm_servicebus_namespace" "sb" {
  name                = "snowtfagentbus"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── App Service Plan for Function App ──────────────────────────────────────
module "function_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-func-snowtf-001"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  sku_name            = "Y1"
  os_type             = "Linux"

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id   = "RITM0010042"
  }
}

# ── Storage Account for Function App ───────────────────────────────────────
module "function_storage" {
  source = "../../modules/storage-account"

  name                = "stfuncsnowtf001"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010042"
  }
}

# ── Azure Function App ─────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtf-sb-events"
  resource_group_name        = data.azurerm_resource_group.existing.name
  location                   = "eastus2"
  service_plan_id            = module.function_plan.id
  storage_account_name       = module.function_storage.name
  storage_account_access_key = module.function_storage.primary_access_key

  app_settings = {
    "ServiceBusNamespace" = data.azurerm_servicebus_namespace.sb.name
    "KeyVaultUri"         = data.azurerm_key_vault.kv.vault_uri
  }

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id   = "RITM0010042"
  }
}
