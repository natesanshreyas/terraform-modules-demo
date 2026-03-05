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

  name        = "rg-azure-vm"
  location    = "eastus2"
  environment = "prod"
  cost_center = "CC-12345"
}

# ── Virtual Machine ──────────────────────────────────────────────────────────
module "vm" {
  source = "../../modules/virtual-machine"

  name                = "vm-azure-001"
  resource_group_name = module.rg.name
  location            = "eastus2"
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  admin_password      = var.admin_password
  os_image            = "UbuntuLTS"
  environment         = "prod"
  cost_center         = "CC-12345"

  tags = {
    project   = "azure-vm"
    ticket_id = "RITM0010034"
  }
}

output "vm_id" {
  value = module.vm.vm_id
}

output "public_ip" {
  value = module.vm.public_ip
}