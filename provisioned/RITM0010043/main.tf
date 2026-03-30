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

# ── Data Sources: Existing Infrastructure ────────────────────────────────────
data "azurerm_resource_group" "rg" {
  name = "snow-tf-agent-rg"
}

data "azurerm_container_app_environment" "env" {
  name                = "snow-tf-agent-env"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_storage_account" "reports" {
  name                = "snowtfagentsn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Container App ────────────────────────────────────────────────────────────
module "metrics_container_app" {
  source = "../../modules/container-app"

  name                         = "metrics-reporting-app"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  location                     = "eastus2"

  image_name = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu        = 0.5
  memory     = "1Gi"

  storage_mounts = [
    {
      name                 = "reports"
      storage_account_id   = data.azurerm_storage_account.reports.id
      storage_account_name = data.azurerm_storage_account.reports.name
      share_name           = "reports"
      mount_path           = "/mnt/reports"
    }
  ]

  tags = {
    cost_center = "CC-ANALYTICS-002"
    ticket_id   = "RITM0010043"
  }
}
