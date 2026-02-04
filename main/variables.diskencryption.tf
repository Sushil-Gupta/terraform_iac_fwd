# Variables for Disk Encryption Set configuration

variable "disk_encryption_key_name" {
  description = "Name of the Key Vault key used for disk encryption"
  type        = string
  default     = "aks-disk-encryption-key"
}

variable "key_vault" {
  description = "Configuration for referencing an existing Azure Key Vault used for disk encryption"
  type = object({
    name                = string
    resource_group_name = string
  })
}
