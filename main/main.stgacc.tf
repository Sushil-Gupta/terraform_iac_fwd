# Storage Account using AVM module
module "storage_account" {

  for_each = var.storage_accounts

  source                                  = "Azure/avm-res-storage-storageaccount/azurerm"
  version                                 = "0.6.0"
   name                     = each.value.name
  location                 = var.location
  resource_group_name      = var.spoke_resource_group_name
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type

  # Private endpoint subnet example
  private_endpoints = {
    for pe_name, pe in each.value.private_endpoints : pe.name => {
      name                          = pe.name
      subnet_resource_id            = module.subnets[pe.subnet_key].resource_id
      subresource_name              = pe.subresource_name
      private_dns_zone_resource_ids = [module.private_dns[pe.privatednszone_key].resource_id]
      tags                          = merge(var.tags, var.tags)
    }
  }
  
  shared_access_key_enabled = each.value.shared_access_key_enabled
  # commenting out blob and file properties for now as not needed currently becuase shared key is disabled by organization policy
  # blob_properties = {  
  #   versioning_enabled  = true
  #   change_feed_enabled = true
  #   delete_retention_policy = {
  #     days = 7
  #   }
  #   container_delete_retention_policy = null
  #   restore_policy                    = null
  # }
  # containers = each.value.containers != {} ? {
  #   for key, value in each.value.containers : key => merge({ name = "stgblob-${each.value.name}-${key}" }, value)
  # } : null
  # shares = {
  #   file1 = {
  #     name  = "stgfile-${each.value.name}"
  #     quota = 8
  #   }
  # }

  queue_properties = {}
  role_assignments = merge(
    {
      runner_stg_admin_role = {
        role_definition_id_or_name = "Storage Account Contributor"
        principal_id               = module.managed_identity.principal_id
      },
      runner_stg_blob_data_contributor = {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = module.managed_identity.principal_id
      }
    },
    try(each.value.role_assignments, {})
  )

  tags = merge(each.value.tags, var.tags)
  # diagnostic_settings_blob = {
  #   default = {
  #     name                  = "diag-stgblob-${var.environment}-${var.app_name}${var.instance}"
  #     workspace_resource_id = module.log_analytics_workspace.resource_id
  #     log_categories        = each.value.log_categories_blob
  #     log_groups            = each.value.log_groups_blob
  #     metric_categories     = each.value.metric_categories_blob
  #   }
  # }

  # diagnostic_settings_file = {
  #   default = {
  #     name                  = "diag-stgfile-${var.environment}-${var.app_name}${var.instance}"
  #     workspace_resource_id = module.log_analytics_workspace.resource_id
  #     log_categories        = each.value.log_categories_file
  #     log_groups            = each.value.log_groups_file
  #     metric_categories     = each.value.metric_categories_file
  #   }
  # }
  # diagnostic_settings_storage_account = {        ---> blob   ---> file
  #   default = {
  #     name                  = "diag-stg-${var.environment}-${var.app_name}${var.instance}"
  #     workspace_resource_id = data.azurerm_log_analytics_workspace.monitor.id
  #     log_categories        = ["audit"]
  #     log_groups            = []
  #     metric_categories     = []
  #   }
  # }

  depends_on = [ module.subnets, 
  module.managed_identity, module.log_analytics_workspace] 
}