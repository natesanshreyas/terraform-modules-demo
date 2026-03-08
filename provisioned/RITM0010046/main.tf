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
  name = "snow-tf-agent-rg"
}

# ── Existing Container Apps Environment ──────────────────────────────────────
data "azurerm_container_app_environment" "env" {
  name                = "snow-tf-agent-env"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Existing Storage Account ─────────────────────────────────────────────────
data "azurerm_storage_account" "reports" {
  name                = "snowtfagentsn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Container App ────────────────────────────────────────────────────────────
module "container_app" {
  source = "../../modules/container-app"

  name                         = "ca-metrics-reporting"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  location                     = "eastus2"

  image = "myregistry.azurecr.io/metrics-reporting:latest"

  storage_account_id = data.azurerm_storage_account.reports.id

  tags = {
    cost_center = "CC-ANALYTICS-002"
    ticket_id  = "RITM0010046"
  }
}

output "container_app_id" {
  value = module.container_app.container_app_id
}
