# Variables for Disk Encryption Set configuration
# Note: key_vault variable is defined in variables.kv.tf (shared across modules)

variable "disk_encryption_key_name" {
  description = "Name of the Key Vault key used for disk encryption"
  type        = string
  default     = "aks-disk-encryption-key"
}
