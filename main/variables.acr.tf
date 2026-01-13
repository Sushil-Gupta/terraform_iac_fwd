variable "container_registry" {
  description = "Configuration for Azure Container Registry"
  type = object({
    name                = string
    resource_group_name = string
    sku                 = optional(string, "Basic")
    private_endpoints_manage_dns_zone_group       = optional(bool, false)   
    lock= optional(object({
            kind = string
            name = optional(string, null)
        }))
    
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    private_endpoints = optional(map(object({
      name                         = optional(string, null)
      subnet_key         = string
      subresource_name   = optional(string)
      privatednszone_key = string
      private_dns_zone_group_name             = optional(string, "default")   
      application_security_group_associations = optional(map(string), {})
      private_service_connection_name         = optional(string, null)
      network_interface_name                  = optional(string, null)
      tags                          = optional(map(string), {})
      ip_configurations = optional(map(object({
        name               = string
        private_ip_address = string
      })), {})
    })), {})
  })
  default = null
}