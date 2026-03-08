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

# ── App Service Plan ─────────────────────────────────────────────────────────
module "service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-snowtf-func-dev"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010045"
  }
}

# ── Storage Account (Function backing storage) ──────────────────────────────
module "storage" {
  source = "../../modules/storage-account"

  name                = "stsnwtffuncdev01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010045"
  }
}

# ── Azure Function App ───────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtf-sb-events-dev"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = "eastus2"
  service_plan_id            = module.service_plan.id
  storage_account_name       = module.storage.name
  storage_account_access_key = module.storage.primary_access_key
  runtime                    = "dotnet"
  environment                = "dev"
  cost_center                = "CC-PLATFORM-001"

  app_settings = {
    SERVICEBUS_NAMESPACE = data.azurerm_servicebus_namespace.sb.name
    KEYVAULT_URI         = data.azurerm_key_vault.kv.vault_uri
  }

  tags = {
    ticket_id = "RITM0010045"
  }
}
