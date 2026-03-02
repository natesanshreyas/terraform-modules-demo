terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  blob_properties {
    versioning_enabled = var.versioning_enabled
  }

  tags = merge(
    {
      environment = var.environment
      cost_center = var.cost_center
      managed_by  = "terraform"
    },
    var.tags
  )
}
