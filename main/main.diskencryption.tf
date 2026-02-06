# ============================================================================
# DISK ENCRYPTION CONFIGURATION - SANDBOX vs CUSTOMER DEPLOYMENT
# ============================================================================
# 
# CURRENT MODE: SANDBOX TESTING (Creates all resources)
# 
# This file supports TWO deployment modes:
# 
# 1. SANDBOX TESTING (CURRENT):
#    - Creates Key Vault, encryption key, DES, and access policies
#    - Use this for local testing before customer deployment
# 
# 2. CUSTOMER DEPLOYMENT:
#    - References existing Key Vault and DES created manually
#    - Switch to data sources (commented section below)
# 
# TO SWITCH FROM SANDBOX TO CUSTOMER DEPLOYMENT:
# Step 1: Comment out all resource blocks (lines ~35-85)
# Step 2: Uncomment all data source blocks (lines ~90-110)
# Step 3: Update outputs to reference data sources
# 
# ============================================================================

# Get current client configuration (needed for tenant ID and object ID)
data "azurerm_client_config" "current" {}

# ============================================================================
# SANDBOX TESTING CONFIGURATION (ACTIVE) - Creates all resources
# ============================================================================

# Create Key Vault for disk encryption
resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault.name
  location                   = var.location
  resource_group_name        = var.key_vault.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true

  # Enable Azure services to access the vault
  enabled_for_disk_encryption = true

  # Network ACLs to allow trusted Azure services
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"  # Allow trusted Microsoft services
  }

  tags = var.tags
  depends_on = [azurerm_resource_group.spoke_rg]
}

# Add access policy for SPN/user running Terraform 
# This grants permissions to whoever is running terraform:
# Uses dynamic object_id so no hardcoded values
resource "azurerm_key_vault_access_policy" "terraform_spn" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Recover",
    "Purge",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Import"
  ]

  depends_on = [azurerm_key_vault.kv]
}

# Create encryption key in Key Vault
resource "azurerm_key_vault_key" "disk_encryption_key" {
  name         = var.disk_encryption_key_name
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  tags = var.tags
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.terraform_spn  # Wait for SPN access policy to be applied
  ]
}

# Create Disk Encryption Set
resource "azurerm_disk_encryption_set" "aks_des" {
  name                = "des-aks-${var.environment}-${var.app_name}"
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.disk_encryption_key.id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
  depends_on = [azurerm_key_vault_key.disk_encryption_key]
}

# Grant DES managed identity access to Key Vault
resource "azurerm_key_vault_access_policy" "des_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_disk_encryption_set.aks_des.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]

  depends_on = [azurerm_disk_encryption_set.aks_des]
}

# # Wait for Key Vault access policy propagation (30 seconds)
# # This prevents EncryptionScopeNotAvailable errors when AKS creates encrypted disks
# resource "time_sleep" "wait_for_kv_propagation" {
#   create_duration = "30s"
  
#   depends_on = [azurerm_key_vault_access_policy.des_policy]
# }

# Grant Managed Identity access to Key Vault for Application Gateway SSL certificates
resource "azurerm_key_vault_access_policy" "appgw_managed_identity" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.managed_identity.principal_id

  certificate_permissions = [
    "Get",
    "List"
  ]

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [module.managed_identity, azurerm_key_vault.kv]
}

# ============================================================================
# CUSTOMER DEPLOYMENT CONFIGURATION (COMMENTED OUT FOR SANDBOX TESTING)
# Uncomment these data sources when deploying to customer with existing resources
# ============================================================================

# # Data source for existing Key Vault
# data "azurerm_key_vault" "existing" {
#   name                = var.key_vault.name
#   resource_group_name = var.key_vault.resource_group_name
# }
# 
# # Data source for existing key in Key Vault for disk encryption
# data "azurerm_key_vault_key" "disk_encryption_key" {
#   name         = var.disk_encryption_key_name
#   key_vault_id = data.azurerm_key_vault.existing.id
# }
# 
# # Data source for existing Disk Encryption Set
# data "azurerm_disk_encryption_set" "aks_des" {
#   name                = "des-aks-${var.environment}-${var.app_name}"
#   resource_group_name = var.spoke_resource_group_name
# }

# ============================================================================
# OUTPUTS (Works for both modes - resource or data source)
# ============================================================================

# Output the DES ID for use in AKS and StorageClass configurations
output "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set for AKS CMK encryption"
  value       = azurerm_disk_encryption_set.aks_des.id
  # CUSTOMER: Change to data.azurerm_disk_encryption_set.aks_des.id
}

output "disk_encryption_set_identity" {
  description = "The managed identity of the Disk Encryption Set"
  value       = azurerm_disk_encryption_set.aks_des.identity[0].principal_id
  # CUSTOMER: Change to data.azurerm_disk_encryption_set.aks_des.identity[0].principal_id
}
