# Terraform configuration for Azure Storage Account

module "resource_group" {
  source = "./modules/resource_group"
  name   = "rg-RITM0010013"
  location = "eastus2"
  tags = {
    ticket_id = "RITM0010013"
    cost_center = ""
  }
}

module "storage_account" {
  source = "./modules/storage_account"
  name = "stgritm0010013"
  resource_group_name = module.resource_group.name
  location = module.resource_group.location
  tags = {
    ticket_id = "RITM0010013"
    cost_center = ""
  }
}

# Output the storage account name
output "storage_account_name" {
  value = module.storage_account.name
}