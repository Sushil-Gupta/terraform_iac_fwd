resource "azurerm_role_assignment" "role-assignment-dnszone" {
  scope                = module.private_dns[var.azure_kubernetes_service.private_dns_zone_key].resource_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         =  module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "role-assignment-contributor-agic" {
  scope                = module.application_gateway[var.azure_kubernetes_service.ingress_application_gateway.gateway_key].resource_id
  role_definition_name = "Contributor"
  principal_id         =   module.avm-res-containerservice-managedcluster.ingress_app_object_id
}

resource "azurerm_role_assignment" "role-assignment-reader-agic" {
  scope                = azurerm_resource_group.spoke_rg.id
  role_definition_name = "Reader"
  principal_id         =  module.avm-res-containerservice-managedcluster.ingress_app_object_id
}

resource "azurerm_role_assignment" "role-assignment-contributor-uami" {
  scope                = module.application_gateway[var.azure_kubernetes_service.ingress_application_gateway.gateway_key].resource_id
  role_definition_name = "Contributor"
  principal_id         =  module.managed_identity.principal_id
    depends_on           = [module.managed_identity, module.application_gateway]  
}

resource "azurerm_role_assignment" "role-assignment-reader-uami" {
  scope                = azurerm_resource_group.spoke_rg.id
  role_definition_name = "Reader"
  principal_id         =  module.managed_identity.principal_id
  depends_on           = [module.managed_identity]  
}

resource "azurerm_role_assignment" "mi-operator-agic" {
  scope                = module.managed_identity.resource_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = module.avm-res-containerservice-managedcluster.ingress_app_object_id
  depends_on           = [module.managed_identity, module.avm-res-containerservice-managedcluster]  
}



module "avm-res-containerservice-managedcluster" {
  source                             = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version                            = "0.3.0"
  resource_group_name                = var.spoke_resource_group_name
  location                           = var.location
  name                               = var.azure_kubernetes_service.name
  sku_tier                           = var.azure_kubernetes_service.sku_tier
  kubernetes_version                 = var.azure_kubernetes_service.kubernetes_version
  oidc_issuer_enabled                = var.azure_kubernetes_service.oidc_issuer_enabled
  workload_identity_enabled          = var.azure_kubernetes_service.workload_identity_enabled
  role_based_access_control_enabled  = var.azure_kubernetes_service.role_based_access_control_enabled
  run_command_enabled                 = var.azure_kubernetes_service.run_command_enabled
  dns_prefix_private_cluster         = var.azure_kubernetes_service.dns_prefix_private_cluster
  private_cluster_enabled            = var.azure_kubernetes_service.private_cluster_enabled
  private_dns_zone_id                 = module.private_dns[var.azure_kubernetes_service.private_dns_zone_key].resource_id  
  role_assignments                   = var.azure_kubernetes_service.role_assignments
  tags                              = merge(var.tags, var.azure_kubernetes_service.tags)
  default_node_pool = {
    name                 = var.azure_kubernetes_service.default_node_pool.name
    vm_size              = var.azure_kubernetes_service.default_node_pool.vm_size
    # enable_auto_scaling  = var.azure_kubernetes_service.default_node_pool.enable_auto_scaling
    os_disk_size_gb      = var.azure_kubernetes_service.default_node_pool.os_disk_size_gb
    os_sku               = var.azure_kubernetes_service.default_node_pool.os_sku
    min_count            = var.azure_kubernetes_service.default_node_pool.min_count
    max_count            = var.azure_kubernetes_service.default_node_pool.max_count
    # node_count           = 1
    auto_scaling_enabled = var.azure_kubernetes_service.default_node_pool.auto_scaling_enabled
    max_pods             = var.azure_kubernetes_service.default_node_pool.max_pods
    vnet_subnet_id       = module.subnets[var.azure_kubernetes_service.default_node_pool.vnet_subnet_key].resource_id
    zones                = var.azure_kubernetes_service.default_node_pool.zones
    node_labels          = var.azure_kubernetes_service.default_node_pool.node_labels
    temporary_name_for_rotation = var.azure_kubernetes_service.default_node_pool.temporary_name_for_rotation
    upgrade_settings    =  {
              drain_timeout_in_minutes      = 0
              max_surge                     = "10%"
              node_soak_duration_in_minutes = 0
            }
  } 
  ingress_application_gateway = {
      gateway_id   = module.application_gateway[var.azure_kubernetes_service.ingress_application_gateway.gateway_key].resource_id
     # gateway_name = "aks-appgw-ingress"
  }
  network_profile = var.azure_kubernetes_service.network_profile
  private_cluster_public_fqdn_enabled = var.azure_kubernetes_service.private_cluster_public_fqdn_enabled
  node_pools                        = var.azure_kubernetes_service.node_pools
  # Configure Managed Identity
  managed_identities = {
    system_assigned = var.azure_kubernetes_service.managed_identities.system_assigned
    user_assigned_resource_ids = setunion(var.azure_kubernetes_service.managed_identities.user_assigned_resource_ids , toset([module.managed_identity.resource_id]))
  }
  diagnostic_settings = {
        default = {
        name                  = "diag-${var.azure_kubernetes_service.name}"
        workspace_resource_id = module.log_analytics_workspace.resource_id
            #     log_categories        = each.value.log_categories
        #     log_groups            = each.value.log_groups
        #     metric_categories     = each.value.metric_categories
        }
    }

  # Configure Azure AD Role-Based Access Control
  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = var.azure_kubernetes_service.azure_active_directory_role_based_access_control.azure_rbac_enabled
    tenant_id          = data.azurerm_client_config.this.tenant_id
    admin_group_object_ids = var.azure_kubernetes_service.azure_active_directory_role_based_access_control.admin_group_object_ids
  }
  private_endpoints = {    
    for pe in var.azure_kubernetes_service.private_endpoints : "aks-${var.app_name}-pe1" => {
      name                          =  "aks-${var.app_name}-pe1"
      subnet_resource_id            = module.subnets[pe.subnet_key].resource_id
      private_dns_zone_resource_ids = [module.private_dns[pe.privatednszone_key].resource_id]      
      tags                          = merge(var.azure_kubernetes_service.tags, var.tags)
      subresource_name              = pe.subresource_name
    }
  }
  private_endpoints_manage_dns_zone_group = var.azure_kubernetes_service.private_endpoints_manage_dns_zone_group
  depends_on = [  azurerm_role_assignment.role-assignment-dnszone]
}