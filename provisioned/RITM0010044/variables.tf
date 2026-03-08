variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = "snow-tf-agent-rg"
}

variable "key_vault_name" {
  type    = string
  default = "snow-tf-kv-sn2025"
}

variable "redis_name" {
  type    = string
  default = "redis-snow-tf-agent"
}

variable "cost_center" {
  type    = string
  default = "CC-PLATFORM-001"
}

variable "ticket_id" {
  type    = string
  default = "RITM0010044"
}
