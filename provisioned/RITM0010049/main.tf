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

# ── Data sources for existing shared infrastructure ─────────────────────────
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_container_app_environment" "env" {
  name                = var.container_app_environment_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "reports" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Container App ────────────────────────────────────────────────────────────
module "container_app" {
  source = "../../modules/container-app"

  name                         = var.container_app_name
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = var.location
  container_app_environment_id = data.azurerm_container_app_environment.env.id

  image = var.container_image
  cpu   = 0.5
  memory = "1Gi"

  storage_mounts = [
    {
      name                 = "reports"
      storage_account_id   = data.azurerm_storage_account.reports.id
      share_name           = var.file_share_name
      mount_path           = "/reports"
    }
  ]

  environment  = var.environment
  cost_center = var.cost_center

  tags = {
    ticket_id = "RITM0010049"
    service   = "metrics-reporting"
  }
}

output "container_app_id" {
  value = module.container_app.container_app_id
}
