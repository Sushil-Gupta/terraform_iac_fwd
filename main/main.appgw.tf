# module "app_gateway_public_ips" {
#   for_each = var.app_gateway_pips
#   source                  = "Azure/avm-res-network-publicipaddress/azurerm"
#   version                 = "0.2.0"
#   name                = each.value.name 
#   location            = var.location
#   resource_group_name = var.spoke_resource_group_name
#   # lock = merge(local.lock, {
#   #   name = "agw-lock-${var.environment}-${var.app_name}${var.instance}-feip"
#   # })
#   tags = merge(each.value.tags, var.tags)
#   diagnostic_settings = {
#     default = {
#       name                  = "diag-${each.value.name}"
#       workspace_resource_id = module.log_analytics_workspace.resource_id
#       # log_categories        = each.value.log_categories
#       # log_groups            = each.value.log_groups
#       # metric_categories     = each.value.metric_categories
#     }
#   }
#     depends_on = [azurerm_resource_group.spoke_rg]
# }

module "application_gateway_policy" {
  source              = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version             = "0.2.0"
  name                  = var.app_gateway_policy.name
  custom_rules         = var.app_gateway_policy.custom_rules
  managed_rules        = var.app_gateway_policy.managed_rules
  policy_settings = var.app_gateway_policy.policy_settings
  location              = var.location
  resource_group_name   = var.spoke_resource_group_name
  tags =  var.tags
    depends_on = [azurerm_resource_group.spoke_rg]
}



# Application Gateway using AVM module
module "application_gateway" {
  for_each = var.app_gateways
  #checkov:skip=CKV_AZURE_120:Using either 'waf_configuration' or 'app_gateway_waf_policy_resource_id'
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.4.3"
  name                  = each.value.name
  location              = var.location
  resource_group_name   = var.spoke_resource_group_name
  sku                   = each.value.sku
  autoscale_configuration = each.value.autoscale_configuration
  frontend_ports        = each.value.frontend_ports
  probe_configurations  = each.value.probe_configurations
  tags                  = merge(var.tags, each.value.tags)
  frontend_ip_configuration_public_name = each.value.frontend_ip_configuration_name
  # public_ip_resource_id                 = module.app_gateway_public_ips[each.value.frontend_ip_key].resource_id
  zones                                 = each.value.zones
  # waf_configuration = each.value.waf_configuration
  managed_identities = {
    user_assigned_resource_ids = [
      module.managed_identity.resource_id # This should be a list of strings, not a list of objects.
    ]
  }
  app_gateway_waf_policy_resource_id = module.application_gateway_policy.resource_id

  # Map each backend address pool to the corresponding App Service instance by using the pool name as the key and retrieving the FQDN from the appsvc module output.
  # This ensures that the Application Gateway routes traffic to the correct App Service based on the configuration in each.value.backend_address_pools.
  backend_address_pools = each.value.backend_address_pools 
  backend_http_settings = {
    for setting in each.value.backend_http_settings : setting.name => {
      name                  = setting.name
      cookie_based_affinity = setting.cookie_based_affinity
      port                  = setting.port
      protocol              = setting.protocol
      pick_host_name_from_backend_address = setting.pick_host_name_from_backend_address
      host_name             = setting.host_name
      path                  = setting.path
      probe_name            = setting.probe_name
    }
  }
  gateway_ip_configuration = {
    name      = each.value.gateway_ip_configuration.name
    subnet_id = module.subnets[each.value.gateway_ip_configuration.subnet_key].resource_id
  }
  http_listeners = {
    for listener in each.value.http_listeners : listener.name => {
      name                           = listener.name
      frontend_ip_configuration_name = listener.frontend_ip_configuration_name
      frontend_port_name             = listener.frontend_port_name
      ssl_certificate_name           = listener.ssl_certificate_name
    }
  }
  request_routing_rules = each.value.request_routing_rules
#   ssl_certificates = {
#     for sslcert in each.value.ssl_certificates : sslcert.name => {
#       name     = sslcert.name
#       data     = sslcert.file_path != null ? filebase64(sslcert.file_path) : null
#       key_vault_secret_id = sslcert.key_vault_details != null ? data.azurerm_key_vault_secret.sslkv_cert[sslcert.name].id : null
#       password = sslcert.key_vault_details == null ? sslcert.password : null
#     }
#   }
  url_path_map_configurations = each.value.url_path_map_configurations
  
  # lock = merge(local.lock, {
  #   name = "agw-lock-${var.environment}-${var.app_name}${var.instance}"
  # })

  
  # allLogs
  diagnostic_settings = {
    default = {
      name                  = "diag-${each.value.name}"
      workspace_resource_id = module.log_analytics_workspace.resource_id
      # log_categories        = each.value.log_categories
      # log_groups            = each.value.log_groups
      # metric_categories     = each.value.metric_categories
    }
  }
  # Removed module.app_gateway_public_ips from depends_on since AVM module creates its own public IP
  depends_on = [ module.application_gateway_policy, module.managed_identity ]
}

