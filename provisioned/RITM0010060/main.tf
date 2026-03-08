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

# ── Existing Container App Environment ───────────────────────────────────────
data "azurerm_container_app_environment" "env" {
  name                = "snow-tf-agent-env"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Existing Storage Account ─────────────────────────────────────────────────
data "azurerm_storage_account" "output" {
  name                = "snowtfagentsn2025"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# ── Container App ────────────────────────────────────────────────────────────
module "metrics_container_app" {
  source = "../../modules/container-app"

  name                         = "ca-metrics-reporting"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  location                     = "eastus2"

  image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

  storage_mounts = [{
    name         = "output"
    account_name = data.azurerm_storage_account.output.name
    share_name   = "metrics-output"
    access_key   = data.azurerm_storage_account.output.primary_access_key
    mount_path   = "/data"
  }]

  tags = {
    cost_center = "CC-ANALYTICS-002"
    ticket_id   = "RITM0010060"
  }
}
