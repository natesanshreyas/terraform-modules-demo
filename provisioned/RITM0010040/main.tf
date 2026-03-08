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

  name        = "rg-cortex-app-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = "UNKNOWN"
}

module "app_service_plan" {
  source = "../../modules/app-service-plan"

  name                = "asp-cortex-dev"
  location            = "eastus2"
  resource_group_name = module.rg.name
  sku_name            = "B1"
  environment         = "dev"
  cost_center         = "UNKNOWN"

  tags = {
    ticket_id = "RITM0010040"
  }
}

module "app_service" {
  source = "../../modules/app-service"

  name                = "app-cortex-payments-dev"
  location            = "eastus2"
  resource_group_name = module.rg.name
  service_plan_id     = module.app_service_plan.id
  environment         = "dev"
  cost_center         = "UNKNOWN"

  tags = {
    ticket_id = "RITM0010040"
  }
}
