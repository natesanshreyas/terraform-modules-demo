variable "resource_group_name" {
  type    = string
  default = "snow-tf-agent-rg"
}

variable "container_app_environment_name" {
  type    = string
  default = "snow-tf-agent-env"
}

variable "storage_account_name" {
  type    = string
  default = "snowtfagentsn2025"
}

variable "file_share_name" {
  type    = string
  default = "reports"
}

variable "container_app_name" {
  type    = string
  default = "ca-metrics-reporting"
}

variable "container_image" {
  type    = string
  default = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
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
  default = "CC-ANALYTICS-002"
}
