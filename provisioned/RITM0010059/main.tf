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
data "azurerm_resource_group" "existing" {
  name = "snow-tf-agent-rg"
}

# ── Existing Service Bus Namespace ───────────────────────────────────────────
data "azurerm_servicebus_namespace" "existing" {
  name                = "snowtfagentbus"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── Existing Key Vault ───────────────────────────────────────────────────────
data "azurerm_key_vault" "existing" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── Storage Account for Function App ─────────────────────────────────────────
module "func_storage" {
  source = "../../modules/storage-account"

  name                = "stfuncsn0059"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  environment         = "prod"
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

# ── App Service Plan ─────────────────────────────────────────────────────────
module "plan" {
  source = "../../modules/service-plan"

  name                = "asp-func-sn0059"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"
  environment         = "prod"
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

# ── Azure Function App ───────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snow-sb-0059"
  resource_group_name        = data.azurerm_resource_group.existing.name
  location                   = "eastus2"
  service_plan_id            = module.plan.id
  storage_account_name       = module.func_storage.name
  storage_account_access_key = module.func_storage.primary_access_key

  app_settings = {
    SERVICEBUS_NAMESPACE = data.azurerm_servicebus_namespace.existing.name
    KEYVAULT_NAME        = data.azurerm_key_vault.existing.name
  }

  environment = "prod"
  cost_center = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}
