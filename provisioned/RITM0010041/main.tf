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

  name        = "rg-ai-storage-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = var.cost_center

  tags = {
    ticket_id = var.ticket_id
  }
}

module "storage" {
  source = "../../modules/storage-account"

  name                = "aistoredev001"
  resource_group_name = module.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  versioning_enabled  = true
  environment         = "dev"
  cost_center         = var.cost_center

  tags = {
    project   = "ai-platform"
    ticket_id = var.ticket_id
  }
}
