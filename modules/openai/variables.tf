variable "name" {
  description = "Name of the Azure OpenAI resource"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region (must support Azure OpenAI)"
  type        = string
  default     = "eastus2"
}

variable "sku_name" {
  description = "SKU: S0"
  type        = string
  default     = "S0"
}

variable "deploy_gpt4" {
  description = "Whether to deploy a GPT-4 model deployment"
  type        = bool
  default     = false
}

variable "gpt4_version" {
  description = "GPT-4 model version"
  type        = string
  default     = "0613"
}

variable "gpt4_capacity" {
  description = "Tokens-per-minute capacity in thousands"
  type        = number
  default     = 10
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center code for billing"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
