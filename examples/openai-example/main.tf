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

# ── Resource Group ───────────────────────────────────────────────────────────
module "rg" {
  source = "../../modules/resource-group"

  name        = "rg-openai-demo-dev"
  location    = "eastus2"
  environment = "dev"
  cost_center = "CC-67890"
}

# ── Azure OpenAI ─────────────────────────────────────────────────────────────
module "openai" {
  source = "../../modules/openai"

  name                = "aoai-demo-wbiq-001"
  resource_group_name = module.rg.name
  location            = "eastus2"
  sku_name            = "S0"
  deploy_gpt4         = true
  gpt4_version        = "0613"
  gpt4_capacity       = 10
  environment         = "dev"
  cost_center         = "CC-67890"

  tags = {
    project   = "workbenchiq-demo"
    ticket_id = "RITM0005678"
  }
}
