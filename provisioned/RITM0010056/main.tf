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

# ── App Service Plan ─────────────────────────────────────────────────────────
module "plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-snowtf-func-dev"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku_name            = "Y1"
  os_type             = "Linux"
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010056"
  }
}

# ── Storage Account for Function App ─────────────────────────────────────────
module "storage" {
  source = "../../modules/storage-account"

  name                = "sntffuncstor001"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  account_tier        = "Standard"
  replication_type    = "LRS"
  versioning_enabled  = false
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010056"
  }
}

# ── Azure Function App ───────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtf-sb-dev"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  service_plan_id            = module.plan.id
  storage_account_name       = module.storage.name
  storage_account_access_key = module.storage.primary_access_key
  environment                = "dev"
  cost_center                = "CC-PLATFORM-001"

  app_settings = {
    SERVICEBUS_NAMESPACE = "snowtfagentbus"
    KEYVAULT_NAME        = "snow-tf-kv-sn2025"
  }

  tags = {
    ticket_id = "RITM0010056"
  }
}
