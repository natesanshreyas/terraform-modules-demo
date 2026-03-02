terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location

  tags = merge(
    {
      environment = var.environment
      cost_center = var.cost_center
      managed_by  = "terraform"
    },
    var.tags
  )
}
