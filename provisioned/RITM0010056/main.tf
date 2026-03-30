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

# ── Data sources for existing shared infrastructure ──────────────────────────
data "azurerm_resource_group" "existing" {
  name = "snow-tf-agent-rg"
}

data "azurerm_servicebus_namespace" "sb" {
  name                = "snowtfagentbus"
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_key_vault" "kv" {
  name                = "snow-tf-kv-sn2025"
  resource_group_name = data.azurerm_resource_group.existing.name
}

# ── App Service Plan ──────────────────────────────────────────────────────────
module "service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-func-snowtf-dev"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = "eastus2"
  sku_name            = "Y1"
  os_type             = "Linux"
  environment         = "dev"
  cost_center         = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010056"
  }
}

# ── Azure Function App ────────────────────────────────────────────────────────
module "function_app" {
  source = "../../modules/function-app"

  name                 = "func-snowtf-sb-dev"
  resource_group_name  = data.azurerm_resource_group.existing.name
  location             = "eastus2"
  service_plan_id      = module.service_plan.id
  storage_account_name = "funcsnowtfdevsa"

  app_settings = {
    SERVICEBUS_NAMESPACE = data.azurerm_servicebus_namespace.sb.name
    KEYVAULT_NAME        = data.azurerm_key_vault.kv.name
  }

  environment = "dev"
  cost_center = "CC-PLATFORM-001"

  tags = {
    ticket_id = "RITM0010056"
  }
}
