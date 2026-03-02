terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_cognitive_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = var.sku_name

  tags = merge(
    {
      environment = var.environment
      cost_center = var.cost_center
      managed_by  = "terraform"
    },
    var.tags
  )
}

resource "azurerm_cognitive_deployment" "gpt4" {
  count                = var.deploy_gpt4 ? 1 : 0
  name                 = "gpt-4"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = var.gpt4_version
  }

  scale {
    type     = "Standard"
    capacity = var.gpt4_capacity
  }
}
