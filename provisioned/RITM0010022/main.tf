# Terraform configuration for storage account

module "storage_infrastructure" {
  source = "./modules/storage_account"
  resource_group_name = "rg-data-team"
  location = "eastus2"
  storage_account_name = "datateamstorage"
  tags = {
    ticket_id = "RITM0010022"
    cost_center = "DATA-001"
  }
}

// modules/storage_account/main.tf
// (Assuming this module exists and handles storage account creation)