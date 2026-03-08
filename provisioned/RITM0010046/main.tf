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

# ── Existing Resource Group ──────────────────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# ── Existing Container Apps Environment ──────────────────────────────────────
data "azurerm_container_app_environment" "env" {
  name                = var.container_app_env_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Existing Storage Account ─────────────────────────────────────────────────
data "azurerm_storage_account" "reports" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Container App ────────────────────────────────────────────────────────────
module "container_app" {
  source = "../../modules/container-app"

  name                         = var.container_app_name
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  location                     = var.location

  image = var.container_image

  storage_mounts = [
    {
      name                 = "reports"
      storage_account_id   = data.azurerm_storage_account.reports.id
      storage_account_name = data.azurerm_storage_account.reports.name
      share_name           = var.storage_share_name
      mount_path           = "/reports"
    }
  ]

  tags = {
    cost_center = var.cost_center
    ticket_id   = var.ticket_id
  }
}
