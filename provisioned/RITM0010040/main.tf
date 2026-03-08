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

# ── Resource Group ───────────────────────────────────────────────────────────
module "rg" {
  source = "../../modules/resource-group"

  name        = "rg-cortex-payments-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = "UNKNOWN"
}

# ── App Service Plan ─────────────────────────────────────────────────────────
module "app_service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-cortex-payments-dev"
  resource_group_name = module.rg.name
  location            = "eastus2"
  sku_name            = "P1v2"
  environment         = "dev"
  cost_center         = "UNKNOWN"

  tags = {
    ticket_id = "RITM0010040"
  }
}

# ── App Service ──────────────────────────────────────────────────────────────
module "app_service" {
  source = "../../modules/app-service"

  name                = "app-cortex-payments-dev"
  resource_group_name = module.rg.name
  location            = "eastus2"
  service_plan_id     = module.app_service_plan.id
  environment         = "dev"
  cost_center         = "UNKNOWN"

  tags = {
    ticket_id = "RITM0010040"
  }
}
