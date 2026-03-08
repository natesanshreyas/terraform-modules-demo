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

  name        = "rg-cortex-payment-API"
  location    = "eastus2"
  environment = "prod"
  tags = {
    cost_center = ""
    ticket_id   = "RITM0010037"
  }
}

# ── App Service ──────────────────────────────────────────────────────────
module "app_service" {
  source = "../../modules/app-service"

  name                = "app-cortex-payment-api"
  resource_group_name = module.rg.name
  location            = "eastus2"
  environment         = "prod"
  tags = {
    project    = "cortex-payment"
    ticket_id  = "RITM0010037"
  }
}

output "app_service_id" {
  value = module.app_service.app_service_id
}

output "app_service_default_hostname" {
  value = module.app_service.default_hostname
}