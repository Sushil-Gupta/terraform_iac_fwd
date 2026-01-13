variable "spoke_vnet"{
  description = "The properties of the spoke virtual network"
  type        = object({
    name                = string
    address_prefix      = string
  })
}

variable "hub_vnet"{
  description = "The properties of the hub virtual network"
  type        = object({
    name                = string
    resource_group_name = string
  })
}

variable "route_table" {
  description = "The route table details"
  type        = object({
    name = string
    firewallPrivateIp = string
  })
}

## Subnet variables
variable "subnets" {
  description = "The subnets to create"
  type = map(object({
    name                            = string
    address_prefix                  = string
    default_outbound_access_enabled = bool
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name = string
      })
    })), [])
    service_endpoints  = optional(list(string), [])
    attach_route_table = optional(bool, false)
  }))
}

## Private DNS Zone variables
variable "private_dns_zones" {
  description = "The private DNS zones to create"
  type = map(object({
    domain_name      = string
    autoregistration = optional(bool, false)
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
  }))
  default = {}
}

## NSG variables
variable "nsg" {
  description = "Network Security Groups (NSGs) configuration"
  type = map(object({
    name         = string
    security_rules = optional(map(object({
      name                       = string
      description                = optional(string)
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string)
      publicip_key               = optional(string, null)
    })), {})
    log_categories    = optional(list(string), ["allLogs"])
    log_groups        = optional(list(string), [])
    metric_categories = optional(list(string), [])
  }))
}