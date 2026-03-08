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

# ── Existing Resource Group ───────────────────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

# ── Storage Account for Function App ─────────────────────────────────────────
module "function_storage" {
  source = "../../modules/storage-account"

  name                = "sntfagentfunc001"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  versioning_enabled  = false
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010048"
  }
}

# ── App Service Plan ──────────────────────────────────────────────────────────
module "asp" {
  source = "../../modules/app-service-plan"

  name                = "asp-snowtf-func"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"
  environment         = "prod"
  cost_center         = "CC-PLATFORM-001"
}

# ── Azure Function App ────────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtf-agent"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = "eastus2"
  service_plan_id            = module.asp.id
  storage_account_name       = module.function_storage.name
  storage_account_access_key = module.function_storage.primary_access_key
  key_vault_name             = "snow-tf-kv-sn2025"
  environment                = "prod"
  cost_center                = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010048"
  }
}
