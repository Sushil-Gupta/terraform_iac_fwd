# Disk Encryption Set for AKS Customer-Managed Key Encryption
# This provides encryption for AKS node disks and persistent volumes

# Data source for existing Key Vault
data "azurerm_key_vault" "existing" {
  name                = var.key_vault.name
  resource_group_name = var.key_vault.resource_group_name
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Data source for existing key in Key Vault for disk encryption
# This key must be created manually in the Azure Portal first
data "azurerm_key_vault_key" "disk_encryption_key" {
  name         = var.disk_encryption_key_name
  key_vault_id = data.azurerm_key_vault.existing.id
}

# disk encryption set resource created manually so used data source here
data "azurerm_disk_encryption_set" "aks_des" {
  name                = "des-aks-${var.environment}-${var.app_name}"
  resource_group_name = var.spoke_resource_group_name
}

# DES access to Key Vault was created manually - access policies are managed
# as part of the Key Vault resource and don't have a separate data source

# Output the DES ID for use in AKS and StorageClass configurations
output "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set for AKS CMK encryption"
  value       = data.azurerm_disk_encryption_set.aks_des.id
}

output "disk_encryption_set_identity" {
  description = "The managed identity of the Disk Encryption Set"
  value       = data.azurerm_disk_encryption_set.aks_des.identity[0].principal_id
}
