### Data block for existing Key Vault (customer-provided resource)
# Uncomment when customer provides their Key Vault name and resource group
# data "azurerm_key_vault" "existing" {
#   name                = var.key_vault.name
#   resource_group_name = var.key_vault.resource_group_name
# }

# Optional: Add role assignments to existing Key Vault if needed
# Uncomment if you need to grant access to your managed identity
# resource "azurerm_role_assignment" "kv_admin" {
#   scope                = data.azurerm_key_vault.existing.id
#   role_definition_name = "Key Vault Administrator"
#   principal_id         = module.managed_identity.principal_id
#   depends_on           = [module.managed_identity]
# }

# Optional: Add private endpoint to existing Key Vault if needed
# Uncomment if customer wants private endpoint in your VNET
# resource "azurerm_private_endpoint" "kv_pe" {
#   name                = "pe-kv-${var.environment}-${var.app_name}"
#   location            = var.location
#   resource_group_name = var.spoke_resource_group_name
#   subnet_id           = module.subnets["private-endpoint"].resource_id
#
#   private_service_connection {
#     name                           = "psc-kv-${var.environment}-${var.app_name}"
#     private_connection_resource_id = data.azurerm_key_vault.existing.id
#     is_manual_connection           = false
#     subresource_names              = ["vault"]
#   }
#
#   private_dns_zone_group {
#     name                 = "pdzg-kv-${var.environment}-${var.app_name}"
#     private_dns_zone_ids = [module.private_dns["keyvault"].resource_id]
#   }
#
#   tags       = var.tags
#   depends_on = [module.subnets, module.private_dns]
# }

# Outputs for application teams
# COMMENTED OUT: Uncomment when data block above is active
#   description = "The resource ID of the existing Key Vault"
#   value       = data.azurerm_key_vault.existing.id
#   sensitive   = false
# }

# output "key_vault_name" {
#   description = "The name of the existing Key Vault"
#   value       = data.azurerm_key_vault.existing.name
#   sensitive   = false
# }

# output "key_vault_uri" {
#   description = "The URI of the Key Vault for application configuration"
#   value       = data.azurerm_key_vault.existing.vault_uri
#   sensitive   = false
# }

# output "key_vault_location" {
#   description = "The location of the existing Key Vault"
#   value       = data.azurerm_key_vault.existing.location
#   sensitive   = false
# }

# output "key_vault_tenant_id" {
#   description = "The tenant ID of the Key Vault"
#   value       = data.azurerm_key_vault.existing.tenant_id
#   sensitive   = false
# }