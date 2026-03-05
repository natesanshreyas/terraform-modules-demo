variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

# To set the password, provide it via tfvars or environment variable.