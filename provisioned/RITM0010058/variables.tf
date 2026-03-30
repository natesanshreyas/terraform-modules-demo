variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "Existing Key Vault name"
}

variable "redis_name" {
  type        = string
  description = "Name of the Azure Redis Cache"
}

variable "cost_center" {
  type        = string
  default     = "CC-PLATFORM-001"
}