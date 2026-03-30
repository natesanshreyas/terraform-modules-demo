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

module "rg" {
  source = "../../modules/resource-group"

  name        = "snow-tf-agent-rg"
  location    = "eastus2"
  environment = "dev"
  cost_center = "CC-ANALYTICS-002"
}

# Reference existing Container App Environment
module "container_app" {
  source = "../../modules/container-app"

  name                = "ca-metrics-reporting"
  resource_group_name = module.rg.name
  location            = "eastus2"
  environment_name    = "snow-tf-agent-env"
  image               = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu                 = 0.5
  memory              = "1Gi"
  environment         = "dev"
  cost_center         = "CC-ANALYTICS-002"

  tags = {
    ticket_id = "RITM0010057"
  }
}
