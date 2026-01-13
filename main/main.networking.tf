resource "azurerm_resource_group" "spoke_rg" {
  name     = var.spoke_resource_group_name
  location = var.location
  tags     = var.tags
}

# Commented out for initial deployment - Hub VNet will be configured by customer
# data "azurerm_virtual_network" "hub_vnet" {
#   name                = var.hub_vnet.name
#   resource_group_name = var.hub_vnet.resource_group_name
# }

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = var.spoke_vnet.name
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  address_space       = [var.spoke_vnet.address_prefix]
  tags                = var.tags
  depends_on = [azurerm_resource_group.spoke_rg]
}

# Commented out for initial deployment - VNet peering will be configured later
# module "peering" {
#   source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
#
#   name                                 = "local-to-remote"
#   parent_id                            = azurerm_virtual_network.spoke_vnet.id
#   remote_virtual_network_id            = data.azurerm_virtual_network.hub_vnet.id
#   allow_forwarded_traffic              = true
#   allow_gateway_transit                = true
#   allow_virtual_network_access         = true
#   create_reverse_peering               = true
#   reverse_allow_forwarded_traffic      = false
#   reverse_allow_gateway_transit        = false
#   reverse_allow_virtual_network_access = true
#   reverse_name                         = "remote-to-local"
#   reverse_use_remote_gateways          = false
#   use_remote_gateways                  = false
# }

resource "azurerm_route_table" "rt" {
  name                = var.route_table.name
  resource_group_name = var.spoke_resource_group_name
  location            = var.location
  tags                = var.tags
  # Commented out - Hub firewall IP will be provided by customer later
  # route {
  #   name           = "fw-route"
  #   address_prefix = var.spoke_vnet.address_prefix
  #   next_hop_type  = "VirtualAppliance"
  #   next_hop_in_ip_address = var.route_table.firewallPrivateIp
  # }
  depends_on = [azurerm_virtual_network.spoke_vnet]
}

#NSG
module "nsg" {
  for_each            = var.nsg
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"
  resource_group_name = var.spoke_resource_group_name
  name                = each.value.name
  location            = var.location
  security_rules = each.value.security_rules 
  # != {} ? {
  #   for key, value in each.value.security_rules : value.name => merge(value, { destination_address_prefix = (value.publicip_key == "appgateway" ? module.app_gateway_public_ips.public_ip_address : value.destination_address_prefix) })
  # } : {}
  diagnostic_settings = {
    default = {
      name                  = "diag-${each.value.name}-${var.instance}"
      workspace_resource_id = module.log_analytics_workspace.resource_id      
    }
  }
  tags = var.tags
  depends_on = [azurerm_route_table.rt, module.log_analytics_workspace]
}


## Subnets
module "subnets" {
  for_each                        = var.subnets
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.10.0"

  name                            = each.value.name
  address_prefix                  = each.value.address_prefix
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  network_security_group          = try({ id = module.nsg[each.key].resource_id }, null)
  route_table                     = strcontains(lower(each.value.name),"bastion") ? null :{
     id = azurerm_route_table.rt.id
  }
  delegation                      = lookup(each.value, "delegation", null)
  service_endpoints               = lookup(each.value, "service_endpoints", null)
  virtual_network = {
    resource_id =   azurerm_virtual_network.spoke_vnet.id
  }
}

## Private DNS Zones
module "private_dns" {
  for_each            = var.private_dns_zones
  source                = "Azure/avm-res-network-privatednszone/azurerm"
  version               = "0.4.2"
  domain_name         = each.value.domain_name
  virtual_network_links = {
      vnet-link-spoke = {
        vnetlinkname     = "vnet-link-spoke-${var.environment}-${var.app_name}${var.instance}"
        vnetid           = azurerm_virtual_network.spoke_vnet.id
        autoregistration = each.value.autoregistration
        tags             = var.tags
      }
      # Commented out for initial deployment - Hub VNet link will be added later
      # vnet-link-hub = {
      #   vnetlinkname     = "vnet-link-hub-${var.environment}-${var.app_name}${var.instance}"
      #   vnetid           = data.azurerm_virtual_network.hub_vnet.id
      #   autoregistration = each.value.autoregistration
      #   tags             = var.tags
      # }
  }
  timeouts = {
    dns_zones = try(each.value.timeouts.dns_zones, {
      create = "120s"
      delete = "120s"
      update = "120s"
      read   = "120s"
    })
    vnet_links = try(each.value.timeouts.vnet_links, {
      create = "120s"
      delete = "120s"
      update = "120s"
      read   = "120s"
    })
  }
  parent_id = azurerm_resource_group.spoke_rg.id
  tags = var.tags
  depends_on = [azurerm_resource_group.spoke_rg]
}