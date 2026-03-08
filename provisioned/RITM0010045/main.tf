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
module "service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-snowtf-func-dev"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  os_type             = "Linux"
  sku_name            = "Y1"
  environment         = "dev"
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

# ── Storage Account for Function App ─────────────────────────────────────────
module "storage" {
  source = "../../modules/storage-account"

  name                = "sntffuncstor001"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  environment         = "dev"
  cost_center         = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

# ── Function App ─────────────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                       = "func-snowtf-sb-dev"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = "eastus2"
  service_plan_id            = module.service_plan.id
  storage_account_name       = module.storage.name
  storage_account_access_key = module.storage.primary_access_key
  key_vault_id               = data.azurerm_key_vault.kv.id
  service_bus_namespace_id   = data.azurerm_servicebus_namespace.sb.id
  environment                = "dev"
  cost_center                = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

output "function_app_name" {
  value = module.function_app.name
}
