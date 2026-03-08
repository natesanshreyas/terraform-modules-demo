variable "ticket_id" {
  type        = string
  description = "ServiceNow ticket ID"
  default     = "RITM0010047"
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing and tagging"
  default     = "CC-PLATFORM-001"
}
