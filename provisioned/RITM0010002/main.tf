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

# Resource Group
module "rg" {
  source = "../../modules/resource-group"
  name        = "rg-storage-demo-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = "CC-CLAIMS-2026"
}

# Storage Account
module "storage" {
  source = "../../modules/storage-account"
  name                = "stdemowbiq001"
  resource_group_name = module.rg.name
  location            = "eastus2"
  account_tier        = "Standard"
  replication_type    = "LRS"
  versioning_enabled  = false
  environment         = "dev"
  cost_center         = "CC-CLAIMS-2026"
  tags = {
    project    = "workbenchiq-demo"
    ticket_id  = "RITM0010002"
  }
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}

output "primary_blob_endpoint" {
  value = module.storage.primary_blob_endpoint
}