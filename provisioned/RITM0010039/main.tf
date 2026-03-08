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

module "rg" {
  source = "../../modules/resource-group"

  name        = "rg-cortex-payments-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = "CC-UNKNOWN"
}

module "app_service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-cortex-payments-dev"
  location            = "eastus2"
  resource_group_name = module.rg.name
  sku_name            = "P1v2"
  os_type             = "Linux"
  environment         = "dev"
  cost_center         = "CC-UNKNOWN"

  tags = {
    ticket_id = "RITM0010039"
  }
}

module "app_service" {
  source = "../../modules/app-service"

  name                = "app-cortex-payments-api-dev"
  location            = "eastus2"
  resource_group_name = module.rg.name
  service_plan_id     = module.app_service_plan.id
  environment         = "dev"
  cost_center         = "CC-UNKNOWN"

  tags = {
    ticket_id = "RITM0010039"
  }
}
