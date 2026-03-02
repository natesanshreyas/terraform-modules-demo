variable "name" {
  description = "Globally unique storage account name (3-24 chars, lowercase alphanumeric)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create the storage account in"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "account_tier" {
  description = "Storage tier: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type: LRS, GRS, RAGRS, ZRS"
  type        = string
  default     = "LRS"
}

variable "versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center code for billing"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
