variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
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
