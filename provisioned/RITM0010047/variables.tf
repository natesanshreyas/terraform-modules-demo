variable "resource_group_name" {
  type        = string
  description = "Existing resource group name"
  default     = "snow-tf-agent-rg"
}

variable "key_vault_name" {
  type        = string
  description = "Existing Key Vault name"
  default     = "snow-tf-kv-sn2025"
}

variable "redis_name" {
  type        = string
  default     = "redis-snowtfagent-dev"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cost_center" {
  type    = string
  default = "CC-PLATFORM-001"
}

variable "ticket_id" {
  type    = string
  default = "RITM0010047"
}
