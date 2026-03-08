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

# ── Existing Service Bus Namespace (reference) ───────────────────────────────
data "azurerm_servicebus_namespace" "sb" {
  name                = "snowtfagentbus"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── App Service Plan ─────────────────────────────────────────────────────────
module "function_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-func-snowtfagent-dev"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id  = "RITM0010059"
  }
}

# ── Storage Account for Function App ─────────────────────────────────────────
module "function_storage" {
  source = "../../modules/storage-account"

  name                = "stfuncsnowtf001"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010059"
  }
}

# ── Azure Function App ───────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtfagent-sb-dev"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = "eastus2"
  service_plan_id            = module.function_plan.id
  storage_account_name       = module.function_storage.name
  storage_account_access_key = module.function_storage.primary_access_key
  runtime                    = "dotnet"

  app_settings = {
    "ServiceBus__Namespace" = data.azurerm_servicebus_namespace.sb.name
    "KeyVaultUri"           = data.azurerm_key_vault.kv.vault_uri
  }

  tags = {
    cost_center = "CC-PLATFORM-001"
    ticket_id  = "RITM0010059"
  }
}
