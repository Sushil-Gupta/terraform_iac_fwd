## Key Vault variables (for existing Key Vault data source)
variable "key_vault" {
  description = "Configuration for referencing an existing Azure Key Vault"
  type = object({
    name                = string
    resource_group_name = string
  })
}