variable "resource_group_name" {
  type    = string
  default = "snow-tf-agent-rg"
}

variable "container_app_env_name" {
  type    = string
  default = "snow-tf-agent-env"
}

variable "storage_account_name" {
  type    = string
  default = "snowtfagentsn2025"
}

variable "storage_share_name" {
  type    = string
  default = "reports"
}

variable "container_app_name" {
  type    = string
  default = "ca-metrics-reporting"
}

variable "container_image" {
  type    = string
  default = "myregistry.azurecr.io/metrics-reporting:latest"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "cost_center" {
  type    = string
  default = "CC-ANALYTICS-002"
}

variable "ticket_id" {
  type    = string
  default = "RITM0010046"
}
