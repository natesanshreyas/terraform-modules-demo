# terraform-modules-demo

Demo Terraform modules used by the **Snow → Terraform Provisioning Agent** as few-shot context when generating infrastructure configurations from ServiceNow tickets.

## Structure

```
modules/
  resource-group/     – azurerm_resource_group
  storage-account/    – azurerm_storage_account
  openai/             – azurerm_cognitive_account (Azure OpenAI)
examples/
  storage-account-example/  – full working example (agent reads this for context)
  openai-example/           – full working example
```

## Usage

The provisioning agent reads example `.tf` files from this repo at runtime to use as few-shot templates when generating new Terraform for incoming tickets. It then opens a PR against this repo with the generated code on a `feature/provision-{ticket_id}` branch.

## Modules

| Module | Resources Created |
|---|---|
| `resource-group` | `azurerm_resource_group` |
| `storage-account` | `azurerm_storage_account` |
| `openai` | `azurerm_cognitive_account` + optional `azurerm_cognitive_deployment` |

All modules accept a `cost_center` variable that gets applied as a resource tag for billing attribution.
